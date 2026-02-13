import { Component, inject, OnInit, signal } from '@angular/core';
import { Router } from '@angular/router';
import { OrderService } from '../services/order.service';
import { Product } from '../models/product.model';

@Component({
  selector: 'app-product-list',
  imports: [],
  templateUrl: './product-list.html',
  styleUrl: './product-list.css',
})
export class ProductList implements OnInit {
  private orderService = inject(OrderService);
  private router = inject(Router);

  products = signal<Product[]>([]);
  loading = signal(true);
  errorMessage = signal('');

  ngOnInit() {
    this.orderService.getProducts().subscribe({
      next: (data) => {
        this.products.set(data);
        this.loading.set(false);
      },
      error: (err) => {
        this.errorMessage.set(err.error?.message ?? 'Failed to load products.');
        this.loading.set(false);
      },
    });
  }

  orderProduct(productId: number) {
    this.router.navigate(['/order'], { queryParams: { productId } });
  }

  getCategoryIcon(category: string): string {
    switch (category) {
      case 'Electronics':
        return 'fa-bolt';
      case 'Accessories':
        return 'fa-plug';
      case 'Furniture':
        return 'fa-chair';
      default:
        return 'fa-tag';
    }
  }
}
