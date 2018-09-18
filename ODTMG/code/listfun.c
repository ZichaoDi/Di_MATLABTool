#include "liststructs.h"
#include "listfun.h"
#include <stdlib.h>
#include <stdio.h>

LINK create_new_list(void){
  LINK head;
  head = malloc(sizeof(ELEMENT));
  if(head==NULL) return NULL;
  head -> d=0.0;
  head -> next= NULL;
  return head;
}


LINK2D create_new_list_2d(void){
  LINK2D head2d;
  head2d = malloc(sizeof(ELEMENT2D));
  if(head2d==NULL) return NULL;
  head2d -> d=create_new_list();
  head2d -> next= NULL;
  return head2d;
}

int append_to_list(LINK this_one){
  LINK last_one;
  LINK new_one;
   
  if(this_one==NULL) return -1;
  last_one=this_one;
  
  while(last_one->next!=NULL) last_one=last_one->next;

  new_one = malloc(sizeof(ELEMENT));
  new_one -> d=0.0;
  new_one -> next= NULL;
  last_one -> next = new_one;
  return 0;
}

int append_to_list_2d(LINK2D this_one){
  LINK2D last_one;
  LINK2D new_one;

  if(this_one==NULL) return -1;
  last_one=this_one;
  
  while(last_one->next!=NULL) last_one=last_one->next;
  new_one = malloc(sizeof(ELEMENT2D));
  if(new_one==NULL) return -1;
  new_one -> d=create_new_list();
  new_one -> next= NULL;
  last_one -> next = new_one;
  return 0;
}


int remove_next_element(LINK the_one_before ){
  LINK the_one_after;
  LINK this_one;

  if(the_one_before==NULL) return -1;
  this_one=the_one_before->next;
  if(this_one==NULL) return -1;

  the_one_after=this_one->next;
  free(this_one);
  the_one_before->next=the_one_after;

  return 0;
}


int remove_next_element_2d(LINK2D the_one_before ){
  LINK2D the_one_after;
  LINK2D this_one;

  if(the_one_before==NULL) return -1;
  this_one=the_one_before->next;
  if(this_one==NULL) return -1;

  the_one_after=this_one->next;
  delete_list(this_one->d);
  free(this_one);
  the_one_before->next=the_one_after;

  return 0;
}

int count_elements(LINK head){
  int count=0;
  LINK cur;
 
  cur=head;

  while(cur!=NULL){
    count++;
    cur=cur->next;
  }

  return count;
}

LINK find_element(LINK head, int index){
  int count=0;
  LINK cur;
 
  cur=head;

  while(cur!=NULL){
    count++;
    if(count==(index+1)) break;
    cur=cur->next;
  }

  return cur;
}

int count_elements_2d(LINK2D head2d){
  int count=0;
  LINK2D cur;
 
  cur=head2d;

  while(cur!=NULL){
    count++;
    cur=cur->next;
  }

  return count;
}

LINK2D find_element_2d(LINK2D head2d, int index){
  int count=0;
  LINK2D cur;
 
  cur=head2d;

  while(cur!=NULL){
    count++;
    if(count==(index+1)) break;
    cur=cur->next;
  }

  return cur;
}

int delete_list(LINK head){
  while(remove_next_element(head)==0);
  free(head);
  return 0;
}

int delete_list_2d(LINK2D head2d){
  while(remove_next_element_2d(head2d)==0);
  delete_list(head2d->d);
  free(head2d);
  return 0;
}

int find_data_in_list(LINK head, DATA val){
  LINK cur;
  int retval=-1, i=0;

  if(head==NULL) return -1;
  cur=head;

  while(cur!=NULL){
    if(cur->d == val){
      retval=i;
      break;
    }
    cur=cur->next;
    i++;
  }
  return retval;
}

int print_int_list_2d(LINK2D head2d){
  int i,j;
  LINK2D cur2d;
  LINK cur;

  i=0;
  cur2d=head2d;
  while(cur2d!=NULL){
    cur=cur2d->d;
    j=0;
    while(cur!=NULL){
      printf("Data(%d,%d): %d\n", i, j++, cur->d);
      cur=cur->next;
    }
    cur2d=cur2d->next;
    i++;
  }
  return 0;
}

/*
int main(void){
  LINK head, cur;
  LINK2D  head2d, cur2d;
  int i,j;


  head2d=create_new_list_2d();
  cur2d=head2d;

  head=cur2d->d;
  cur=head;
  
  cur->d=1.1;
  append_to_list(head);

  cur=cur->next;
  cur->d=2.2;
  append_to_list(head);

  cur=cur->next;
  cur->d=3.3;

  append_to_list_2d(head2d);
  cur2d=cur2d->next;

  head=cur2d->d;
  cur=head;
  
  cur->d=4.4;
  append_to_list(head);

  cur=cur->next;
  cur->d=5.5;


  i=0;
  cur2d=head2d;
  while(cur2d!=NULL){
    cur=cur2d->d;
    j=0;
    while(cur!=NULL){
      printf("Data %d %d: %f\n", i, j++, cur->d);
      cur=cur->next;
    }
    cur2d=cur2d->next;
    i++;
  }


  printf(">  Data %d %d: %f\n", 0,1, find_element(find_element_2d(head2d,0)->d,1)->d);
  printf("%d\n", count_elements_2d(head2d));

  delete_list_2d(head2d);
  head=NULL;
  return 0;
}

*/
