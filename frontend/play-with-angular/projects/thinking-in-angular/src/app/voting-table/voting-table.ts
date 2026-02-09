import { NgClass, NgFor } from '@angular/common';
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-voting-table',
  imports: [
    NgFor,
    NgClass
  ],
  templateUrl: './voting-table.html',
  styleUrl: './voting-table.css',
})
export class VotingTable {

  @Input("value")
  votingLines: Array<any> = []

}
