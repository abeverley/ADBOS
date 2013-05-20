use utf8;
package ADBOS::Schema::Result::Sigtype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ADBOS::Schema::Result::Sigtype

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

=head1 TABLE: C<sigtype>

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


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-05-20 00:21:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AdWmsD14zrWFb79JVGoqug


# You can replace this text with custom content, and it will be preserved on regeneration
1;
