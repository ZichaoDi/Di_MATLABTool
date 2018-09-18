LINK create_new_list(void);
LINK2D create_new_list_2d(void);

int append_to_list(LINK);
int append_to_list_2d(LINK2D);

int remove_next_element(LINK);
int remove_next_element_2d(LINK2D);

int delete_list(LINK);
int delete_list_2d(LINK2D);

int count_elements(LINK head);
LINK find_element(LINK head, int index);

int count_elements_2d(LINK2D head2d);
LINK2D find_element_2d(LINK2D head2d, int index);

int find_data_in_list(LINK head, DATA val);

int print_int_list_2d(LINK2D head2d);

