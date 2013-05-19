package ADBOS::Schema::Result::Sigtype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ADBOS::Schema::Result::Sigtype

=cut

__PACKAGE__->table("sigtype");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 search

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "search",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 signals

Type: has_many

Related object: L<ADBOS::Schema::Result::Signal>

=cut

__PACKAGE__->has_many(
  "signals",
  "ADBOS::Schema::Result::Signal",
  { "foreign.sigtype" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2013-05-07 21:24:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4oOaVwfWomE8UuSDhIAXWQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
