import { NgClass, NgFor, NgIf } from '@angular/common';
import { Component, EventEmitter, Output } from '@angular/core';
import { Product } from '../product/product';

@Component({
  selector: 'app-product-list',
  imports: [
    NgClass,
    NgIf,
    NgFor,
    Product,
  ],
  templateUrl: './product-list.html',
  styleUrl: './product-list.css',
})
export class ProductList {


  @Output() buy: EventEmitter<any> = new EventEmitter();

  products: Array<any> = [
    {
      id: 1,
      name: 'Laptop',
      price: 10000.0,
      currencyCode: 'INR',
      description: 'A high-performance laptop for all your computing needs.',
      imageUrl: '/Laptop.png',
      isAvailable: true,
      makeDate: Date.now() // timestamp in milliseconds
    },
    {
      id: 2,
      name: 'Smartphone',
      price: 5000.0,
      currencyCode: 'INR',
      description: 'A sleek smartphone with the latest features and technology.',
      imageUrl: 'Mobile.png',
      isAvailable: true,
      makeDate: Date.now() // timestamp in milliseconds
    },
  ];

  addToCart(product: any) {
    this.buy.emit(product);
  }


}
