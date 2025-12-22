package com.anthony.demo;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class App {
    public static void main(String[] args) throws IOException {
        System.out.println("Starting Anthony's CI/CD demo web service...");
        
        // Create HTTP server on port 8080
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        
        // Create context for root path
        server.createContext("/", new RootHandler());
        server.createContext("/health", new HealthHandler());
        
        // Start the server
        server.setExecutor(null);
        server.start();
        
        System.out.println("Server started on port 8080");
        System.out.println("Visit http://localhost:8080 to see the demo!");
    }
    
    static class RootHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = "Hello, this is Anthony's CI/CD demo! 🚀\n" +
                            "Server is running successfully!\n" +
                            "Timestamp: " + new java.util.Date();
            
            exchange.getResponseHeaders().set("Content-Type", "text/plain");
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
            
            System.out.println("Request handled at " + new java.util.Date());
        }
    }
    
    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = "OK";
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
}