package ADBOS::Schema::Result::Category;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ADBOS::Schema::Result::Category

=cut

__PACKAGE__->table("category");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 1
  size: 2

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "char", is_nullable => 1, size => 2 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 opdefs_category_prevs

Type: has_many

Related object: L<ADBOS::Schema::Result::Opdef>

=cut

__PACKAGE__->has_many(
  "opdefs_category_prevs",
  "ADBOS::Schema::Result::Opdef",
  { "foreign.category_prev" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opdefs_categories

Type: has_many

Related object: L<ADBOS::Schema::Result::Opdef>

=cut

__PACKAGE__->has_many(
  "opdefs_categories",
  "ADBOS::Schema::Result::Opdef",
  { "foreign.category" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2013-05-06 20:53:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qSxKE0iQjZe80etg7lh4aA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
