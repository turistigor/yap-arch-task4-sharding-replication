# Настройка API gateway и Service Discovery

Схема масштабирования: [drawio](arch.drawio) | [png](arch.png).

В этом задании, в отличии о предыдущих, не просили прикладывать инструкции и осуществлять какое-либо развертывание, однако я заинтересовался темой и решил проделать эту работу. По этой причине инструкция менее подробная, чем в других заданиях, где её просили явно.

<details>
<summary> Инструкция </summary>

- Запуск и настройка необходимых сервисов.
  ```bash
  ./run.sh
  ```

- Проверка работы балансировки:
  ```bash
  # Первый терминал: мониторинг логов 1ого инстанса
  watch -d "docker-compose logs pymongo_api1 | tail"

  # Второй терминал: мониторинг логов 2ого инстанса
  watch -d "docker-compose logs pymongo_api2 | tail"

  # Третий терминал: запросы
  curl http://localhost:9080
  curl http://localhost:9080
  curl http://localhost:9080
  # ...
  ```
Ожидаемый результат: запросы распределяются между инстансами равномерно.

В ходе тестирования были замечены локальные отклонения от равномерности (до 5 запросов), однако статистика неизбежно выравнивается с ростом числа запросов.

- Проверка отказоустойчивости:
  ```bash
  # Первый терминал: мониторинг логов 1ого инстанса
  watch -d "docker-compose logs pymongo_api1 | tail"

  # Второй терминал: мониторинг логов 2ого инстанса
  watch -d "docker-compose logs pymongo_api2 | tail"

  # Третий терминал
  docker-compose stop pymongo_api1
  curl http://localhost:9080
  curl http://localhost:9080
  curl http://localhost:9080

  docker-compose start pymongo_api1
  docker-compose stop pymongo_api2
  curl http://localhost:9080
  curl http://localhost:9080
  curl http://localhost:9080

  docker-compose start pymongo_api2
  curl http://localhost:9080
  curl http://localhost:9080
  curl http://localhost:9080
  ```
  Ожидаемый результат:
  - После отключения pymongo_api1 все запросы успешно обрабатываются pymongo_api2.
  - После включения pymongo_api1 и включения pymongo_api2 все запросы успешно обрабатываются pymongo_api1.
  - После включения pymongo_api2 запросы распределяются равномерно.

- Проверка возможностей ServiceDiscovery:
  ```bash
  # Первый терминал: мониторинг логов 1ого инстанса
  watch -d "docker-compose logs pymongo_api1 | tail"

  # Второй терминал: мониторинг логов 2ого инстанса
  watch -d "docker-compose logs pymongo_api2 | tail"

  # Третий терминал
  # Дерегистрируем один из инстансов в Consul
  curl -X PUT "http://localhost:8500/v1/agent/service/deregister/pymongo-api1"
  curl http://localhost:9080
  curl http://localhost:9080
  curl http://localhost:9080

  # Снова зарегистрируем один из инстансов в Consul
  curl "http://127.0.0.1:8500/v1/agent/service/register" -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "ID": "pymongo-api1",
    "Name": "pymongo-api",
    "Tags": ["pymongo-api", "v1"],
    "Address": "'173.17.5.1'",
    "Port": 8080,
    "Weights": {
      "Passing": 10,
      "Warning": 1
    }
  }'
  curl http://localhost:9080
  curl http://localhost:9080
  curl http://localhost:9080
  ```
  Ожидаемый результат:
  - После дерегистрации pymongo_api1 все запросы успешно обрабатываются pymongo_api2.
  - После повторной регистрации pymongo_api1 запросы распределяются равномерно.

</details>
