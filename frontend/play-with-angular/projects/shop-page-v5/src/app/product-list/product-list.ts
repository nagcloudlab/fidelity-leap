import { NgClass, NgFor, NgIf } from '@angular/common';
import { Component, EventEmitter, Output } from '@angular/core';
import { Product } from '../product/product';
import { ActivatedRoute, RouterLink, RouterLinkActive } from '@angular/router';
import { ProductServicce } from '../product-servicce';

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


  products: Array<any> = []


  constructor(private route: ActivatedRoute, private productService: ProductServicce) { }

  ngOnInit() {
    this.route.params.subscribe(params => {
      const category = params['category'];
      if (category !== undefined) {
        this.productService.getProductsByCategory(category).subscribe(products => {
          this.products = products.filter(product => product.category === category);
        });
      }
    });



  }



}
