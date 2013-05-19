package ADBOS::Schema::Result::Task;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ADBOS::Schema::Result::Task

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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "onbrief",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
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


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2013-05-05 10:29:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JEKEH7z6EB/QJnNwfvIH8g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
