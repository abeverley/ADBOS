use utf8;
package ADBOS::Schema::Result::Task;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ADBOS::Schema::Result::Task

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

=head1 TABLE: C<tasks>

=cut

__PACKAGE__->table("tasks");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 onbrief

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 ordering

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "onbrief",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "ordering",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 ships

Type: has_many

Related object: L<ADBOS::Schema::Result::Ship>

=cut

__PACKAGE__->has_many(
  "ships",
  "ADBOS::Schema::Result::Ship",
  { "foreign.tasks_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-07-05 16:15:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZS5XXNoyF3/8kiI5fDXKMQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
