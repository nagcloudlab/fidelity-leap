import { NgClass, NgFor, NgIf } from '@angular/common';
import { Component, EventEmitter, Output } from '@angular/core';
import { Product } from '../product/product';
import { ActivatedRoute, RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-product-list',
  imports: [
    NgClass,
    NgIf,
    NgFor,
    Product,
    RouterLink,
    RouterLinkActive
  ],
  templateUrl: './product-list.html',
  styleUrl: './product-list.css',
})
export class ProductList {



  allProducts: Array<any> = [
    {
      id: 1,
      name: 'Laptop',
      price: 10000.0,
      currencyCode: 'INR',
      description: 'A high-performance laptop for all your computing needs.',
      imageUrl: '/Laptop.png',
      isAvailable: true,
      makeDate: Date.now(), // timestamp in milliseconds,
      category: 'electronics'
    },
    {
      id: 2,
      name: 'Smartphone',
      price: 5000.0,
      currencyCode: 'INR',
      description: 'A sleek smartphone with the latest features and technology.',
      imageUrl: 'Mobile.png',
      isAvailable: true,
      makeDate: Date.now(),
      category: 'electronics'
    },
    // Add more products as needed but not electronics
    {
      id: 3,
      name: 'T-Shirt',
      price: 500.0,
      currencyCode: 'INR',
      description: 'A comfortable and stylish t-shirt for everyday wear.',
      imageUrl: 'T-Shirt.png',
      isAvailable: true,
      makeDate: Date.now(),
      category: 'other'
    },
  ];

  products: Array<any> = []


  constructor(private route: ActivatedRoute) { }

  ngOnInit() {
    this.route.params.subscribe(params => {
      const category = params['category'];
      console.log('Category:', category);
      this.products = this.allProducts.filter(product => product.category === category);
      console.log('Filtered Products:', this.products);
    });
  }



}
