use utf8;
package ADBOS::Schema::Result::Opdef;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ADBOS::Schema::Result::Opdef

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

=head1 TABLE: C<opdefs>

=cut

__PACKAGE__->table("opdefs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 type

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 defrep

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=head2 number

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 number_serial

  data_type: 'smallint'
  is_nullable: 1

=head2 number_year

  data_type: 'smallint'
  is_nullable: 1

=head2 category

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 erg_code

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 parent_equip

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 defective_unit

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 line5

  data_type: 'text'
  is_nullable: 1

=head2 defect

  data_type: 'text'
  is_nullable: 1

=head2 repair_int

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 assistance

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 assistance_port

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 matdem

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 ships_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 rectified

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 cancelled

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 onbrief

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 created

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 modified

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 modified_sigtype

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 remarks

  data_type: 'text'
  is_nullable: 1

=head2 category_prev

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 category_changed

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "type",
  { data_type => "char", is_nullable => 1, size => 2 },
  "defrep",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
  "number",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "number_serial",
  { data_type => "smallint", is_nullable => 1 },
  "number_year",
  { data_type => "smallint", is_nullable => 1 },
  "category",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "erg_code",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "parent_equip",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "defective_unit",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "line5",
  { data_type => "text", is_nullable => 1 },
  "defect",
  { data_type => "text", is_nullable => 1 },
  "repair_int",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "assistance",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "assistance_port",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "matdem",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "ships_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rectified",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "cancelled",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "onbrief",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "created",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "modified",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "modified_sigtype",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "remarks",
  { data_type => "text", is_nullable => 1 },
  "category_prev",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "category_changed",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 category

Type: belongs_to

Related object: L<ADBOS::Schema::Result::Category>

=cut

__PACKAGE__->belongs_to(
  "category",
  "ADBOS::Schema::Result::Category",
  { id => "category" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 category_prev

Type: belongs_to

Related object: L<ADBOS::Schema::Result::Category>

=cut

__PACKAGE__->belongs_to(
  "category_prev",
  "ADBOS::Schema::Result::Category",
  { id => "category_prev" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 comments

Type: has_many

Related object: L<ADBOS::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "ADBOS::Schema::Result::Comment",
  { "foreign.opdefs_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 modified_sigtype

Type: belongs_to

Related object: L<ADBOS::Schema::Result::Sigtype>

=cut

__PACKAGE__->belongs_to(
  "modified_sigtype",
  "ADBOS::Schema::Result::Sigtype",
  { id => "modified_sigtype" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 ship

Type: belongs_to

Related object: L<ADBOS::Schema::Result::Ship>

=cut

__PACKAGE__->belongs_to(
  "ship",
  "ADBOS::Schema::Result::Ship",
  { id => "ships_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 signals

Type: has_many

Related object: L<ADBOS::Schema::Result::Signal>

=cut

__PACKAGE__->has_many(
  "signals",
  "ADBOS::Schema::Result::Signal",
  { "foreign.opdefs_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-07-26 08:07:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o8i8cdt3vCNrdPzAdS5OkA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
