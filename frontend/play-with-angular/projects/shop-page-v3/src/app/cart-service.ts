import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class CartService {

  public $cart: BehaviorSubject<Array<any>> = new BehaviorSubject<Array<any>>([]);

  constructor() {
    console.log('CartService instance created');
  }

  cart: Array<any> = []; // global state 
  addToCart(product: any) {
    this.cart.push(product);
    this.$cart.next([...this.cart]); // publish the updated cart to all subscribers
  }





}
