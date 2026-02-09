import { NgFor } from '@angular/common';
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-review',
  imports: [
    NgFor
  ],
  templateUrl: './review.html',
  styleUrl: './review.css',
})
export class Review {
  @Input() review: any;
}
