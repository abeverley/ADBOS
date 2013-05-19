package ADBOS::Schema::Result::Signal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ADBOS::Schema::Result::Signal

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
  is_nullable: 1

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
  { data_type => "datetime", is_nullable => 1 },
  "type",
  {
    data_type => "enum",
    extra => { list => ["OPDEF", "SITREP", "RECT", "STORES", "OTHER"] },
    is_nullable => 1,
  },
  "sigtype",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 sigtype

Type: belongs_to

Related object: L<ADBOS::Schema::Result::Sigtype>

=cut

__PACKAGE__->belongs_to(
  "sigtype",
  "ADBOS::Schema::Result::Sigtype",
  { id => "sigtype" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 opdef

Type: belongs_to

Related object: L<ADBOS::Schema::Result::Opdef>

=cut

__PACKAGE__->belongs_to(
  "opdef",
  "ADBOS::Schema::Result::Opdef",
  { id => "opdefs_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2013-05-05 10:29:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5/baDny6kAAU3A/r7x1O6g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
