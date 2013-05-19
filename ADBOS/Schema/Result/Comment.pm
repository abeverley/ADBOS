package ADBOS::Schema::Result::Comment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ADBOS::Schema::Result::Comment

=cut

__PACKAGE__->table("comments");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 opdefs_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 users_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 time

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "opdefs_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "users_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "time",
  { data_type => "datetime", is_nullable => 1 },
);
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
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 user

Type: belongs_to

Related object: L<ADBOS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "ADBOS::Schema::Result::User",
  { id => "users_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2013-05-05 10:29:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OdOWCUvklA1JU7P7pbfC7Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
