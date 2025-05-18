#!/bin/bash

# Stop on error
set -e

# Usage: ./create-sveltekit-firebase.sh my-app-name
APP_NAME=$1
PROJECT_ID="sveltekit-${APP_NAME}"
REGION="us-central"

echo "🛠 Creating new SvelteKit project: $APP_NAME"

# Clone your GitHub template (replace with your actual template repo)
npx degit dhust/sveltekit-template $APP_NAME
cd $APP_NAME

# Initialize git
git init
pnpm install

echo "🚀 Creating Firebase project: $PROJECT_ID"
gcloud projects create $PROJECT_ID --name="$APP_NAME"
firebase projects:addfirebase $PROJECT_ID

# Set this project locally
firebase use --add $PROJECT_ID

echo "🔥 Initializing Firestore and Hosting"
firebase init firestore hosting --project=$PROJECT_ID --non-interactive

echo ""
echo "📋  NOW GO TO:"
echo "     https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
echo "     → Scroll to 'Your apps' > Register a Web App (if needed)"
echo "     → Copy the full config object that looks like:"
echo "     {"
echo "       apiKey: '...',"
echo "       authDomain: '...',"
echo "       ...etc"
echo "     }"
echo ""
read -p "📥 Paste your Firebase config JSON (one line, or multiline, end with Ctrl-D): " -d '' CONFIG

# Use Node.js to parse and convert to .env format
node -e "
let config;
try {
  config = eval('(' + \`${CONFIG}\` + ')');
} catch (e) {
  console.error('\n❌ Invalid config pasted. Exiting.');
  process.exit(1);
}

const fs = require('fs');
const env = Object.entries(config)
  .map(([k, v]) => \`VITE_FIREBASE_\${k.toUpperCase()}=\${v}\`)
  .join('\n');
fs.writeFileSync('.env', env + '\n');
console.log('✅ .env file created!');
"

# Add firebase.ts file if not already included
mkdir -p src/lib/firebase
cat > src/lib/firebase/firebase.ts <<EOF
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID
};

export const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
EOF

echo "🎉 All done! You can now run: pnpm dev"
