# Спринт 10 — PowerShell: Мониторинг внешнего сайта (готово к сдаче)

**Автор:** Рувен  
**Дата:** 23.08.2025  
**Тема:** Скрипт PowerShell для проверки доступности сайта `mail.ru` с логированием и метриками.

---

## 1. Подготовка окружения
- ОС: Ubuntu 22.04 LTS
- PowerShell 7.x установлен из репозитория Microsoft.
- Лог‑каталог и файл:
  - Каталог: `/var/log/web_checks` (права `750`, владелец `ruven`)
  - Файл логов: `/var/log/web_checks/script.log` (права `640`, владелец `ruven`)

Команды (выполнялись ранее):
```bash
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get install -y powershell

sudo mkdir -p /var/log/web_checks
sudo touch /var/log/web_checks/script.log
sudo chown ruven:ruven /var/log/web_checks /var/log/web_checks/script.log
sudo chmod 750 /var/log/web_checks
sudo chmod 640 /var/log/web_checks/script.log
```

---

## 2. Скрипт `web_check.ps1`
Функции:
- **WebRequest** — основная: проверка параметра, цикл по портам 80/443 × 3 итерации, `Invoke-WebRequest`, сбор метрик.
- **CalcTime** — среднее время ответа (мс).
- **CalcWeight** — средний размер ответа (байты).
- **Write-Log** — единое логирование в консоль и файл.

> Скрипт выводит **только свои** сообщения об ошибках (системные скрыты), как требует ТЗ.

См. файл скрипта: [web_check.ps1](script/web_check.ps1)

---

## 3. Команды запуска и результаты

### 3.1. Успешный запуск (без UFW)
Команда:
```bash
sudo ufw disable
pwsh ~/scripts/ps/web_check.ps1 mail.ru
```
Пример результата (см. также `webcheck_ok.txt`):
```text
[2025-08-23T18:41:03] [INFO] Старт проверки доступности: mail.ru (порты: 80, 443, итераций: 3)
[2025-08-23T18:41:05] [INFO] [port 80][#1] 200 OK — время: 2122.06мс; размер: 936 байт.
[2025-08-23T18:41:07] [INFO] [port 80][#2] 200 OK — время: 1447.92мс; размер: 936 байт.
[2025-08-23T18:41:08] [INFO] [port 80][#3] 200 OK — время: 1380.61мс; размер: 936 байт.
[2025-08-23T18:41:09] [INFO] [port 443][#1] 200 OK — время: 1207.21мс; размер: 936 байт.
[2025-08-23T18:41:11] [INFO] [port 443][#2] 200 OK — время: 1237.73мс; размер: 936 байт.
[2025-08-23T18:41:12] [INFO] [port 443][#3] 200 OK — время: 1310.79мс; размер: 936 байт.
[2025-08-23T18:41:12] [INFO] Все итерации успешны по портам 80 и 443.
[2025-08-23T18:41:12] [INFO] Среднее время ответа: 1451.05 мс
[2025-08-23T18:41:12] [INFO] Средний размер ответа: 936 байт
```

### 3.2. Моделирование недоступности (UFW)
Команды:
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw deny out 443/tcp
sudo ufw show added
sudo ufw enable

pwsh ~/scripts/ps/web_check.ps1 mail.ru

sudo ufw disable
```
Ожидаемый результат при блокировке исходящего 443 (см. также `webcheck_ufw_denied.txt`):
```text
[2025-08-23T18:55:00] [INFO] Старт проверки доступности: mail.ru (порты: 80, 443, итераций: 3)
[2025-08-23T18:55:01] [INFO] [port 80][#1] 200 OK — время: 900.00мс; размер: 936 байт.
[2025-08-23T18:55:02] [INFO] [port 80][#2] 200 OK — время: 800.00мс; размер: 936 байт.
[2025-08-23T18:55:03] [INFO] [port 80][#3] 200 OK — время: 850.00мс; размер: 936 байт.
[2025-08-23T18:55:04] [ERROR] [port 443][#1] Ошибка выполнения запроса (https://mail.ru:443/). Сайт недоступен.
```

### 3.3. Запуск без параметра
Команда:
```bash
pwsh ~/scripts/ps/web_check.ps1
```
Результат (см. также `webcheck_noparam.txt`):
```text
[2025-08-23T17:58:34] [ERROR] Не передан параметр URL. Пример: pwsh ./web_check.ps1 https://mail.ru
```

---

## 4. Логи
Все сообщения пишутся в `/var/log/web_checks/script.log`. Пример проверки:
```bash
tail -n 50 /var/log/web_checks/script.log
```

---

## 5. Критерии соответствия (чек‑лист)
- [x] Скрипт получает адрес сайта из параметра `$url`.
- [x] Есть проверки: передан ли параметр; успешность выполнения команды; доступность на портах 80 и 443 (по 3 итерации).
- [x] При успехе коды **200** на всех итерациях для каждого порта.
- [x] При отклонении — понятное сообщение и завершение.
- [x] Есть функции `WebRequest`, `CalcTime`, `CalcWeight`, общая `Write-Log`.
- [x] Код читаемый: комментарии, отступы, имена переменных понятные.
- [x] Использованы циклы и условные операторы.
- [x] Сообщения понятные, без системных стэктрейсов.

---

## 6. Приложения
- Скриншот выполнения: [test.png](screens/test.png)
- [webcheck_ok.txt](logs/webcheck_ok.txt) — успешный прогон
- [webcheck_ufw_denied.txt](logs/webcheck_ufw_denied.txt) — UFW‑блокировка
- [webcheck_noparam.txt](logs/webcheck_noparam.txt) — запуск без параметра
- `web_check.ps1` — файл скрипта (финальная версия).
- `webcheck_ok.txt` — вывод успешного прогона.
- `webcheck_ufw_denied.txt` — вывод при блокировке 443/tcp через UFW.
- `webcheck_noparam.txt` — вывод при запуске без параметра.
- Логи: `/var/log/web_checks/script.log` (на ВМ).