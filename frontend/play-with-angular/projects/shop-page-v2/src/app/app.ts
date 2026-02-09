import { NgClass, NgForOf, NgIf } from '@angular/common';
import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Navbar } from './navbar/navbar';
import { ProductList } from './product-list/product-list';
import { CartBadge } from './cart-badge/cart-badge';
import { CartView } from './cart-view/cart-view';

@Component({
  selector: 'app-root',
  imports: [
    NgForOf,
    NgIf,
    NgClass,
    Navbar,
    ProductList,
    CartBadge,
    CartView
  ],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('shop-page-v1');

  cart: Array<any> = [];

  addToCart(product: any) {
    //this.cart.push(product); // mutating the array, so that we can see the change in the cart badge and cart view
    this.cart = [...this.cart, product]; // creating a new array, so that we can see the change in the cart badge and cart view
  }

  isCartVisible = false;
  toggleCart() {
    this.isCartVisible = !this.isCartVisible;
  }




}
