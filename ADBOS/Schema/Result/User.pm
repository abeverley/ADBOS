package ADBOS::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ADBOS::Schema::Result::User

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 forename

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 type

  data_type: 'enum'
  extra: {list => ["viewer","member","admin"]}
  is_nullable: 1

=head2 created

  data_type: 'datetime'
  is_nullable: 1

=head2 pwchanged

  data_type: 'datetime'
  is_nullable: 1

=head2 lastlogin

  data_type: 'datetime'
  is_nullable: 1

=head2 deleted

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "forename",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "type",
  {
    data_type => "enum",
    extra => { list => ["viewer", "member", "admin"] },
    is_nullable => 1,
  },
  "created",
  { data_type => "datetime", is_nullable => 1 },
  "pwchanged",
  { data_type => "datetime", is_nullable => 1 },
  "lastlogin",
  { data_type => "datetime", is_nullable => 1 },
  "deleted",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 comments

Type: has_many

Related object: L<ADBOS::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "ADBOS::Schema::Result::Comment",
  { "foreign.users_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2013-05-05 10:29:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VP+IncXVzw42jwm/luz10g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
