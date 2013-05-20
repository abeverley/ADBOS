use utf8;
package ADBOS::Schema::Result::Signal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ADBOS::Schema::Result::Signal

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

=head1 TABLE: C<signals>

=cut

__PACKAGE__->table("signals");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 content

  data_type: 'text'
  is_nullable: 1

=head2 opdefs_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sitrep

  data_type: 'smallint'
  is_nullable: 1

=head2 dtg

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 originator

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 type

  data_type: 'enum'
  extra: {list => ["OPDEF","SITREP","RECT","STORES","OTHER"]}
  is_nullable: 1

=head2 sigtype

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 1 },
  "opdefs_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sitrep",
  { data_type => "smallint", is_nullable => 1 },
  "dtg",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "originator",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "type",
  {
    data_type => "enum",
    extra => { list => ["OPDEF", "SITREP", "RECT", "STORES", "OTHER"] },
    is_nullable => 1,
  },
  "sigtype",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 opdef

Type: belongs_to

Related object: L<ADBOS::Schema::Result::Opdef>

=cut

__PACKAGE__->belongs_to(
  "opdef",
  "ADBOS::Schema::Result::Opdef",
  { id => "opdefs_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 sigtype

Type: belongs_to

Related object: L<ADBOS::Schema::Result::Sigtype>

=cut

__PACKAGE__->belongs_to(
  "sigtype",
  "ADBOS::Schema::Result::Sigtype",
  { id => "sigtype" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-05-20 00:21:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L7YxV0Lg96lIlUYOPOwuOw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
