cd website
npm run build
rsync -r build/ beng-ubuntu:~/kagladder-website-build
