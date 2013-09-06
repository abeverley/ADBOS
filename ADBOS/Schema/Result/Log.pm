use utf8;
package ADBOS::Schema::Result::Log;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ADBOS::Schema::Result::Log

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

=head1 TABLE: C<log>

=cut

__PACKAGE__->table("log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 users_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 message

  data_type: 'text'
  is_nullable: 1

=head2 time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "users_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "message",
  { data_type => "text", is_nullable => 1 },
  "time",
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

=head2 user

Type: belongs_to

Related object: L<ADBOS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "ADBOS::Schema::Result::User",
  { id => "users_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-09-04 07:25:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fMGvB9nNxwFp9dRnHHEpuQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
