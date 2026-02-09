import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-voting-item',
  imports: [],
  templateUrl: './voting-item.html',
  styleUrl: './voting-item.css',
})
export class VotingItem {

  @Input() value: string = 'Unknown';
  @Input() totalVotes: number = 0;

  @Output() vote = new EventEmitter<any>(); // Observable 

  handleVote(vote: string) {
    if (vote === 'like') {
      this.vote.emit({ item: this.value, type: 'like' });
    } else if (vote === 'dislike') {
      this.vote.emit({ item: this.value, type: 'dislike' });
    }
  }


}
