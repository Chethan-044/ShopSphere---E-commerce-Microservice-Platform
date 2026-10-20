package com.shopsphere.gateway.filter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Slf4j
@Component
public class JwtAuthenticationFilter implements GlobalFilter, Ordered {

    private final AntPathMatcher pathMatcher = new AntPathMatcher();

    private static final List<String> OPEN_ENDPOINTS = List.of(
            "/api/v1/auth/**",
            "/actuator/**"
    );

    private static final String PRODUCTS_PATH = "/api/v1/products/**";

    private final SecretKey key;

    public JwtAuthenticationFilter(@Value("${jwt.secret}") String secret) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getURI().getPath();

        // Skip authentication for open endpoints
        if (isOpenEndpoint(path)) {
            return chain.filter(exchange);
        }

        // Allow GET requests to products without authentication
        if (pathMatcher.match(PRODUCTS_PATH, path) && HttpMethod.GET.equals(request.getMethod())) {
            return chain.filter(exchange);
        }

        // Extract Authorization header
        String authHeader = request.getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return onError(exchange, "Missing or invalid Authorization header", HttpStatus.UNAUTHORIZED);
        }

        String token = authHeader.substring(7);

        try {
            Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            String userId = claims.getSubject();
            @SuppressWarnings("unchecked")
            List<String> roles = claims.get("roles", List.class);
            String rolesStr = roles != null ? String.join(",", roles) : "";

            // Enforce RBAC for admin-only operations
            if (isAdminEndpoint(request)) {
                if (roles == null || !roles.contains("ROLE_ADMIN")) {
                    log.warn("Access denied to {}: User {} does not have ROLE_ADMIN", path, userId);
                    return onError(exchange, "Access denied: Administrator privileges required", HttpStatus.FORBIDDEN);
                }
            }

            // Add user info headers to downstream request
            ServerHttpRequest modifiedRequest = request.mutate()
                    .header("X-User-Id", userId)
                    .header("X-User-Roles", rolesStr)
                    .build();

            return chain.filter(exchange.mutate().request(modifiedRequest).build());

        } catch (Exception e) {
            log.error("JWT validation failed: {}", e.getMessage());
            return onError(exchange, "Invalid or expired token", HttpStatus.UNAUTHORIZED);
        }
    }

    private boolean isOpenEndpoint(String path) {
        return OPEN_ENDPOINTS.stream()
                .anyMatch(pattern -> pathMatcher.match(pattern, path));
    }

    private boolean isAdminEndpoint(ServerHttpRequest request) {
        String path = request.getURI().getPath();
        HttpMethod method = request.getMethod();

        // Admin user management (listing all users or deleting users)
        if ("/api/v1/users".equals(path) && HttpMethod.GET.equals(method)) {
            return true;
        }
        if (pathMatcher.match("/api/v1/users/**", path) && HttpMethod.DELETE.equals(method)) {
            return true;
        }

        // Product management (creating, updating, deleting products)
        if (pathMatcher.match(PRODUCTS_PATH, path) &&
                (HttpMethod.POST.equals(method) || HttpMethod.PUT.equals(method) || HttpMethod.DELETE.equals(method))) {
            return true;
        }

        // Review moderation
        if (pathMatcher.match("/api/v1/reviews/pending", path) ||
                pathMatcher.match("/api/v1/reviews/*/approve", path) ||
                pathMatcher.match("/api/v1/reviews/*/reject", path) ||
                pathMatcher.match("/api/v1/reviews/*/feature", path) ||
                pathMatcher.match("/api/v1/reviews/*/unfeature", path)) {
            return true;
        }

        // Order status moderation
        if (pathMatcher.match("/api/v1/orders/status/**", path) ||
                (pathMatcher.match("/api/v1/orders/*/status", path) && HttpMethod.PATCH.equals(method))) {
            return true;
        }

        // Shipment status updates
        if (pathMatcher.match("/api/v1/shipments/*/status", path) && HttpMethod.PUT.equals(method)) {
            return true;
        }

        return false;
    }

    private Mono<Void> onError(ServerWebExchange exchange, String message, HttpStatus status) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(status);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);

        String body = String.format("{\"status\":%d,\"error\":\"%s\",\"message\":\"%s\"}",
                status.value(), status.getReasonPhrase(), message);
        DataBuffer buffer = response.bufferFactory().wrap(body.getBytes(StandardCharsets.UTF_8));

        return response.writeWith(Mono.just(buffer));
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
