# Настройка кэшированного шардирования с репликацией и запуск системы

Нижеприведенная последовательность команд опирается на ранее подготовленные скрипты.

- Запуск и настройка необходимых сервисов.
  ```bash
  ./run.sh
  ```

- Проверка включенности кэша:
  ```bash
  curl http://127.0.0.1:8080
  ```
Ожидаемый результат в поле "cache_enabled": true.

- Проверка быстродействия с кэшом (повторить несколько раз):
  ```bash
  curl -s -o /dev/null -w "Status: %{http_code}\\nTotal time: %{time_total}s\\n" http://127.0.0.1:8080/helloDoc/users
  ```
  Ожидаемый результат:
  - Status: 200
    Total time: 1.032847s
  - Status: 200
    Total time: 0.007039s
  - Status: 200
    Total time: 0.006140s

- Для сравнения можно отключить кэширование и увидеть:
  ```bash
  curl http://127.0.0.1:8080
  ```
  Ожидаемый результат в поле "cache_enabled": false.

  ```bash
  curl -s -o /dev/null -w "Status: %{http_code}\\nTotal time: %{time_total}s\\n" http://127.0.0.1:8080/helloDoc/users
  ```

  Ожидаемый результат:
  - Status: 200
    Total time: 1.011722s
  - Status: 200
    Total time: 1.016435s
  - Status: 200
    Total time: 1.010782s

- Для очистки (вместе с volumes) можно использовать команду
  ```bash
  docker-compose down -v
  ```