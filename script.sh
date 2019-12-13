sudo apt update -y
sudo apt install npm -y
sudo npm install pm2@latest -g -y
pm2 stop all
pm2 start nodejs/app.js
