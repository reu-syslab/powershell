# Sprint 10 — PowerShell WebCheck

Скрипт PowerShell для мониторинга внешнего сайта (пример: `mail.ru`).  
Задание курса **Яндекс Практикум — Системный администратор (Linux)**.

##  Возможности
- Проверка доступности сайта по портам **80** и **443** (по 3 итерации).
- Проверка кода ответа (`200 OK`).
- Подсчёт среднего времени отклика и среднего размера ответа.
- Логирование в консоль и файл `/var/log/web_checks/script.log`.
- Обработка ошибок: выводятся **только свои сообщения**, без системных трейсбеков.
- Эмуляция недоступности через `ufw`.

##  Структура репозитория
```
.
├── README.md
├── Sprint10_Web_Check.md
├── logs
│   ├── webcheck_noparam.txt
│   ├── webcheck_ok.txt
│   └── webcheck_ufw_denied.txt
├── screens
│   └── test.png
└── script
    └── web_check.ps1
```
 - [Sprint10_Web_Check.md](Sprint10_Web_Check.md) # - подробный отчёт
 - [web_check.ps1](script/web_check.ps1) # — скрипт
 - [webcheck_noparam.txt](logs/webcheck_noparam.txt) - без параметра
 - [webcheck_ok.txt](logs/webcheck_ok.txt) - успешный прогон
 - [webcheck_ufw_denied.txt](logs/webcheck_ufw_denied.txt) - недоступность (ufw)
 - [test.png](screens/test.png)



## ✍️ Автор
Рувен • 2025
