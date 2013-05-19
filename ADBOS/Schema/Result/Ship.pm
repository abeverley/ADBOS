package ADBOS::Schema::Result::Ship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ADBOS::Schema::Result::Ship

=cut

__PACKAGE__->table("ships");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 tasks_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "tasks_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 opdefs

Type: has_many

Related object: L<ADBOS::Schema::Result::Opdef>

=cut

__PACKAGE__->has_many(
  "opdefs",
  "ADBOS::Schema::Result::Opdef",
  { "foreign.ships_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 task

Type: belongs_to

Related object: L<ADBOS::Schema::Result::Task>

=cut

__PACKAGE__->belongs_to(
  "task",
  "ADBOS::Schema::Result::Task",
  { id => "tasks_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2013-05-05 10:29:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VjWgzHk2mBF05twbc5f5tg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
