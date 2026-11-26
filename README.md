# SwiftDrop Backend

REST API and WebSocket server for the SwiftDrop food delivery app. Mobile app: [swiftdrop-flutter](https://github.com/123marwan/swiftdrop-flutter).

## Features
- Register and login (customer / driver), password hashing with BCrypt
- Stateless JWT authentication (custom filter)
- Role-based access control (CUSTOMER, DRIVER) with Spring Security
- Orders: customers create orders and see only their own; drivers see pending orders, accept them and update status
- Restaurants and menu items endpoints
- Real-time updates with STOMP over WebSocket: new pending orders and live driver location

## Tech
Java, Spring Boot, Spring Security, Spring Data JPA / Hibernate, MySQL, WebSocket (STOMP), Maven

## Main endpoints
- `/api/auth/**` register and login
- `/api/orders/create`, `/all`, `/pending`, `/accept/{id}`, `/update-status/{id}`
- `/api/restaurants`, `/api/restaurants/{id}/menu`
- WebSocket: `/ws`, topics `/topic/order.pending` and `/topic/live-tracking`

## How to run
1. Create a MySQL database named `swiftdrop_db`.
2. Edit `swiftdrop/src/main/resources/application.properties` (database user and password, JWT secret).
3. `cd swiftdrop`
4. `./mvnw spring-boot:run` (server on port 8080)
