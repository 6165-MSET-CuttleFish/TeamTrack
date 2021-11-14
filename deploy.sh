# Deploy cloud functions
cd backend
./deploy.sh

# Deploy android frontend
cd ..
flutter build appbundle

# Deploy ios frontend
flutter build ios --release
