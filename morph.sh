#!/bin/bash

# Логотип
echo -e '\e[32m'
echo -e '███╗   ██╗ ██████╗ ██████╗ ███████╗██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗ '
echo -e '████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗'
echo -e '██╔██╗ ██║██║   ██║██║  ██║█████╗  ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝'
echo -e '██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗'
echo -e '██║ ╚████║╚██████╔╝██████╔╝███████╗██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║'
echo -e '╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝'
echo -e '\e[0m'

echo -e "\nПодписаться на канал may.crypto{🦅} чтобы быть в курсе самых актуальных нод - https://t.me/maycrypto\n"

sleep 2

while true; do
  # Меню
  PS3='Выберите опцию: '
  options=("Установить ноду Morph" "Удалить ноду Morph" "Проверить работоспособность ноды" "Добавить мониторинг через Telegram Бота" "Покинуть скрипт")
  select opt in "${options[@]}"
  do
      case $opt in
          "Установить ноду Morph")
              echo "Начинаем установку ноды Morph..."

              # Обновление системы и установка необходимых пакетов
              echo "Обновление системы и установка необходимых пакетов..."
              sudo apt update && sudo apt upgrade -y
              sudo apt install curl git jq lz4 build-essential unzip make lz4 gcc jq ncdu tmux cmake clang pkg-config libssl-dev python3-pip protobuf-compiler bc -y

              # Установка GO
              echo "Установка Go..."
              sudo rm -rf /usr/local/go
              curl -Ls https://go.dev/dl/go1.22.2.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
              eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
              eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
              go version

              # Установка Docker и Docker Compose
              echo "Установка Docker и Docker Compose..."
              sudo apt install -y ca-certificates curl gnupg lsb-release
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
              sudo usermod -aG docker $USER
              newgrp docker
              sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose

              # Установка Geth
              echo "Установка Geth..."
              mkdir -p ~/.morph
              cd ~/.morph
              git clone https://github.com/morph-l2/morph.git
              cd morph
              git checkout v0.1.0-beta
              make nccc_geth
              cd ~/.morph/morph/node
              make build

              # Загрузка и распаковка данных
              echo "Загрузка и распаковка данных..."
              cd ~/.morph
              wget https://raw.githubusercontent.com/morph-l2/config-template/main/holesky/data.zip
              unzip data.zip

              # Создание Secret Key
              echo "Создание Secret Key..."
              cd ~/.morph
              openssl rand -hex 32 > jwt-secret.txt
              cat jwt-secret.txt

              # Запуск ноды Geth
              echo "Запуск ноды Geth..."
              screen -S geth -d -m ~/.morph/morph/go-ethereum/build/bin/geth --morph-holesky \
                  --datadir "./geth-data" \
                  --http --http.api=web3,debug,eth,txpool,net,engine \
                  --http.port 8546 \
                  --authrpc.addr localhost \
                  --authrpc.vhosts="localhost" \
                  --authrpc.port 8551 \
                  --authrpc.jwtsecret=./jwt-secret.txt \
                  --miner.gasprice="100000000" \
                  --log.filename=./geth.log \
                  --port 30363

              # Запуск Morph ноды
              echo "Запуск Morph ноды..."
              screen -S morph -d -m ~/.morph/morph/node/build/bin/morphnode --home ./node-data \
                  --l2.jwt-secret ./jwt-secret.txt \
                  --l2.eth http://localhost:8546 \
                  --l2.engine http://localhost:8551 \
                  --log.filename ./node.log

              echo "Установка завершена!"
              break
              ;;
              
          "Удалить ноду Morph")
              echo "Удаление ноды Morph..."
              sudo rm -rf ~/.morph
              sudo docker system prune -a -f
              echo "Нода Morph успешно удалена!"
              break
              ;;
              
          "Проверить работоспособность ноды")
              echo "Проверка работоспособности ноды..."
              curl -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":74}' http://localhost:8546
              curl http://localhost:26657/status
              break
              ;;
              
          "Добавить мониторинг через Telegram Бота")
              read -p "Введите API ключ от Telegram Бота: " API_KEY
              read -p "Введите ваш User ID в Telegram: " USER_ID
              read -p "Введите интервал проверки (в секундах, по умолчанию 600): " CHECK_INTERVAL
              CHECK_INTERVAL=${CHECK_INTERVAL:-600}  # Значение по умолчанию 600 секунд

              echo $API_KEY > ~/.morph/telegram_bot_api_key.txt
              echo $USER_ID > ~/.morph/telegram_bot_user_id.txt
              echo $CHECK_INTERVAL > ~/.morph/telegram_bot_check_interval.txt
              
              echo "Устанавливаем Python зависимости..."
              sudo apt install python3-pip -y
              pip3 install requests python-telegram-bot
              echo "Создаем и запускаем скрипт мониторинга..."
              cat <<EOF > ~/.morph/node_monitor.py
import requests
import time
import json
from telegram import Bot

# Чтение API ключа, User ID и интервала проверки
with open('~/.morph/telegram_bot_api_key.txt') as f:
    api_key = f.read().strip()

with open('~/.morph/telegram_bot_user_id.txt') as f:
    user_id = f.read().strip()

with open('~/.morph/telegram_bot_check_interval.txt') as f:
    check_interval = int(f.read().strip())

bot = Bot(token=api_key)

# Функция для проверки состояния ноды
def check_node_status():
    try:
        response_geth = requests.post('http://localhost:8546', json={"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":74})
        response_morph = requests.get('http://localhost:26657/status')

        if response_geth.status_code == 200 and response_morph.status_code == 200:
            geth_data = response_geth.json()
            morph_data = response_morph.json()
            
            message = f"🟢 Нода Morph работает корректно!\n\n" \
                      f"🔗 Geth Peer Count: {geth_data['result']}\n" \
                      f"📝 Morph Node Status: {json.dumps(morph_data, indent=2)}"
            bot.send_message(chat_id=user_id, text=message)
        else:
            bot.send_message(chat_id=user_id, text="🔴 Проблемы с нодой Morph!")
    except Exception as e:
        bot.send_message(chat_id=user_id, text=f"⚠️ Ошибка при проверке ноды: {e}")

# Основной цикл мониторинга
if __name__ == "__main__":
    notifications_enabled = True
    
    while True:
        if notifications_enabled:
            check_node_status()
        
        time.sleep(check_interval)
EOF
              chmod +x ~/.morph/node_monitor.py
              echo "Запуск скрипта мониторинга..."
              screen -S telegram_bot -d -m python3 ~/.morph/node_monitor.py
              echo "Мониторинг ноды через Telegram Бота установлен!"
              break
              ;;
              
          "Покинуть скрипт")
              echo "Выход..."
              exit 0
              ;;
              
          *) echo "Неверный выбор, попробуйте снова.";;
      esac
  done
done
