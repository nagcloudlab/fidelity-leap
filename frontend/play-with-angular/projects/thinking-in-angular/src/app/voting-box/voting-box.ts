import { Component } from '@angular/core';
import { VotingItem } from '../voting-item/voting-item';
import { VotingTable } from '../voting-table/voting-table';
import { NgFor } from '@angular/common';

@Component({
  selector: 'app-voting-box',
  imports: [
    VotingItem,
    VotingTable,
    NgFor
  ],
  templateUrl: './voting-box.html',
  styleUrl: './voting-box.css',
})
export class VotingBox {

  votingLines: Array<any> = [
    { name: 'Angular', likes: 10, dislikes: 1 },
    { name: 'React', likes: 20, dislikes: 2 },
    { name: 'Vue', likes: 15, dislikes: 0 }
  ];

  handleVote(vote: any) {
    let { item, type } = vote;
    let votingLine = this.votingLines.find(line => line.name === item);
    if (votingLine) {
      if (type === 'like') {
        votingLine.likes++;
      } else if (type === 'dislike') {
        votingLine.dislikes++;
      }
    }
  }

}
