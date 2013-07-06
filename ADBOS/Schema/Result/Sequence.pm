use utf8;
package ADBOS::Schema::Result::Sequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ADBOS::Schema::Result::Sequence

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

=head1 TABLE: C<sequence>

=cut

__PACKAGE__->table("sequence");

=head1 ACCESSORS

=head2 ti

  data_type: 'integer'
  is_nullable: 0

=head2 received

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ti",
  { data_type => "integer", is_nullable => 0 },
  "received",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</ti>

=back

=cut

__PACKAGE__->set_primary_key("ti");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-07-06 08:10:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vV2r0qVPFPK1aoeT1lguAw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
