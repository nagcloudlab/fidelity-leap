package com.example.orderservice.service;

import com.example.orderservice.client.AccountsClient;
import com.example.orderservice.dto.OrderRequestDto;
import com.example.orderservice.dto.OrderResponseDto;
import com.example.orderservice.dto.OrderResponseDto.OrderItemResponseDto;
import com.example.orderservice.entity.Order;
import com.example.orderservice.entity.OrderItem;
import com.example.orderservice.entity.Product;
import com.example.orderservice.event.OrderEvent;
import com.example.orderservice.event.OrderEvent.OrderItemEvent;
import com.example.orderservice.event.OrderEventPublisher;
import com.example.orderservice.exception.InsufficientBalanceException;
import com.example.orderservice.exception.ResourceNotFoundException;
import com.example.orderservice.repository.OrderRepository;
import com.example.orderservice.repository.ProductRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final OrderEventPublisher eventPublisher;
    private final AccountsClient accountsClient;

    public OrderService(OrderRepository orderRepository,
                        ProductRepository productRepository,
                        OrderEventPublisher eventPublisher,
                        AccountsClient accountsClient) {
        this.orderRepository = orderRepository;
        this.productRepository = productRepository;
        this.eventPublisher = eventPublisher;
        this.accountsClient = accountsClient;
    }

    public List<OrderResponseDto> getAllOrders() {
        return orderRepository.findAllByOrderByOrderDateDesc().stream()
                .map(this::toResponseDto)
                .toList();
    }

    public OrderResponseDto getOrderById(Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + id));
        return toResponseDto(order);
    }

    @Transactional
    public OrderResponseDto createOrder(OrderRequestDto dto) {
        Order order = new Order();
        order.setCustomerName(dto.getCustomerName());
        order.setCustomerEmail(dto.getCustomerEmail());
        order.setStatus("CONFIRMED");

        double totalAmount = 0;
        java.util.Map<Long, Product> productLookup = new java.util.HashMap<>();

        for (var itemDto : dto.getItems()) {
            Product product = productRepository.findById(itemDto.getProductId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Product not found with id: " + itemDto.getProductId()));
            productLookup.put(product.getId(), product);

            OrderItem item = new OrderItem();
            item.setOrder(order);
            item.setProductId(product.getId());
            item.setProductName(product.getName());
            item.setQuantity(itemDto.getQuantity());
            item.setUnitPrice(product.getPrice());
            item.setLineTotal(product.getPrice() * itemDto.getQuantity());

            order.getItems().add(item);
            totalAmount += item.getLineTotal();
        }

        order.setTotalAmount(totalAmount);

        // Check balance with accounts-service
        Map<String, Object> balanceCheck = accountsClient.checkBalance(
                dto.getCustomerEmail(), totalAmount);
        if (!Boolean.TRUE.equals(balanceCheck.get("sufficient"))) {
            throw new InsufficientBalanceException(
                    "Insufficient balance for " + dto.getCustomerEmail() +
                    ". Available: $" + String.format("%.2f", ((Number) balanceCheck.get("balance")).doubleValue()) +
                    ", Required: $" + String.format("%.2f", totalAmount));
        }

        Order saved = orderRepository.save(order);

        // Debit the account
        accountsClient.debit(dto.getCustomerEmail(), totalAmount, saved.getId());

        // Publish Kafka event
        OrderEvent event = new OrderEvent();
        event.setOrderId(saved.getId());
        event.setCustomerName(saved.getCustomerName());
        event.setCustomerEmail(saved.getCustomerEmail());
        event.setOrderDate(saved.getOrderDate());
        event.setStatus(saved.getStatus());
        event.setTotalAmount(saved.getTotalAmount());
        event.setItemCount(saved.getItems().size());
        event.setItems(saved.getItems().stream()
                .map(i -> {
                    Product p = productLookup.get(i.getProductId());
                    return new OrderItemEvent(
                            i.getProductId(), i.getProductName(),
                            p != null ? p.getCategory() : "", p != null ? p.getBrand() : "",
                            i.getQuantity(), i.getUnitPrice(), i.getLineTotal());
                })
                .toList());

        eventPublisher.publish(event);

        return toResponseDto(saved);
    }

    private OrderResponseDto toResponseDto(Order order) {
        List<OrderItemResponseDto> items = order.getItems().stream()
                .map(i -> new OrderItemResponseDto(
                        i.getId(), i.getProductId(), i.getProductName(),
                        i.getQuantity(), i.getUnitPrice(), i.getLineTotal()))
                .toList();

        return new OrderResponseDto(
                order.getId(),
                order.getCustomerName(),
                order.getCustomerEmail(),
                order.getOrderDate(),
                order.getStatus(),
                order.getTotalAmount(),
                items
        );
    }
}
