use utf8;
package ADBOS::Schema::Result::Category;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ADBOS::Schema::Result::Category

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<category>

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

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-05-20 00:21:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CDDJdCdC+ekXuD4mvPzb6g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
