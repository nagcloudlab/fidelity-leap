import { Component, inject, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { OrderService } from '../services/order.service';
import { AccountsService, Account, BalanceResponse } from '../services/accounts.service';
import { Product } from '../models/product.model';

@Component({
  selector: 'app-order-form',
  imports: [FormsModule],
  templateUrl: './order-form.html',
  styleUrl: './order-form.css',
})
export class OrderForm implements OnInit {
  private orderService = inject(OrderService);
  private accountsService = inject(AccountsService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  products = signal<Product[]>([]);
  accounts = signal<Account[]>([]);
  customerName = '';
  customerEmail = '';
  selectedProductId = 0;
  quantity = 1;
  errorMessage = signal('');
  successMessage = signal('');
  loading = signal(false);
  balanceInfo = signal<BalanceResponse | null>(null);
  balanceLoading = signal(false);

  ngOnInit() {
    this.orderService.getProducts().subscribe({
      next: (data) => {
        this.products.set(data);
        const productId = Number(this.route.snapshot.queryParamMap.get('productId'));
        if (productId) {
          this.selectedProductId = productId;
        }
      },
    });
    this.accountsService.getAllAccounts().subscribe({
      next: (data) => this.accounts.set(data),
    });
  }

  onAccountSelect() {
    const account = this.accounts().find((a) => a.customerEmail === this.customerEmail);
    if (account) {
      this.customerName = account.customerName;
      this.onEmailBlur();
    } else {
      this.customerName = '';
      this.balanceInfo.set(null);
    }
  }

  onEmailBlur() {
    if (this.customerEmail && this.customerEmail.includes('@')) {
      this.balanceLoading.set(true);
      this.accountsService.getAccount(this.customerEmail).subscribe({
        next: (data) => {
          this.balanceInfo.set(data);
          this.balanceLoading.set(false);
        },
        error: () => {
          this.balanceInfo.set(null);
          this.balanceLoading.set(false);
        },
      });
    } else {
      this.balanceInfo.set(null);
    }
  }

  getSelectedProduct(): Product | undefined {
    return this.products().find((p) => p.id === this.selectedProductId);
  }

  getTotal(): number {
    const product = this.getSelectedProduct();
    return product ? product.price * this.quantity : 0;
  }

  onSubmit() {
    this.errorMessage.set('');
    this.successMessage.set('');

    if (!this.customerName || !this.customerEmail || !this.selectedProductId || this.quantity < 1) {
      this.errorMessage.set('Please fill in all fields.');
      return;
    }

    this.loading.set(true);
    this.orderService
      .placeOrder({
        customerName: this.customerName,
        customerEmail: this.customerEmail,
        items: [{ productId: this.selectedProductId, quantity: this.quantity }],
      })
      .subscribe({
        next: (order) => {
          this.loading.set(false);
          this.successMessage.set(
            `Order #${order.id} placed successfully! Total: $${order.totalAmount.toFixed(2)}`,
          );
          this.customerName = '';
          this.customerEmail = '';
          this.selectedProductId = 0;
          this.quantity = 1;
          this.balanceInfo.set(null);
        },
        error: (err) => {
          this.loading.set(false);
          this.errorMessage.set(err.error?.message ?? 'Failed to place order.');
        },
      });
  }

  viewOrders() {
    this.router.navigate(['/orders']);
  }
}
