typedef int DATA;

struct linked_list {
  DATA                 d;
  struct linked_list   *next;
};

typedef struct linked_list  ELEMENT;
typedef ELEMENT             *LINK;


struct list_2D {
  LINK             d;
  struct list_2D   *next;
};
typedef struct list_2D      ELEMENT2D ;
typedef ELEMENT2D           *LINK2D;


