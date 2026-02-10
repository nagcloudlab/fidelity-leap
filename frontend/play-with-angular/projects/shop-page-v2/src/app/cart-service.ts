import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class CartService {

  constructor() {
    console.log('CartService instance created');
  }

  private cart: Array<any> = []; // global state 

  addToCart(product: any) {
    this.cart = [...this.cart, product];
    console.log('Cart:', this.cart);
  }


}
