import { ComponentFixture, TestBed } from '@angular/core/testing';

import { VotingTable } from './voting-table';

describe('VotingTable', () => {
  let component: VotingTable;
  let fixture: ComponentFixture<VotingTable>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [VotingTable]
    })
    .compileComponents();

    fixture = TestBed.createComponent(VotingTable);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
