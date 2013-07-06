package Chess::Rep::Coverage::Imager;
# ABSTRACT: Expose chess ply potential energy with Imager

=head1 NAME

Chess::Rep::Coverage::Imager - Expose chess ply potential energy with Imager

=cut

use strict;
use warnings;

use base 'Chess::Rep::Coverage';

use Imager;
use Imager::Fill;
use Imager::Font;
use Imager::Color;

our $VERSION = '0.0301';

=head1 SYNOPSIS

  use Chess::Rep::Coverage::Imager;

  my $g = Chess::Rep::Coverage::Imager->new();
  $g->write('board', 'png');

  $g->set_from_fen('8/8/8/3pr3/4P3/8/8/8 w ---- - 0 1');
  $g->coverage(); # Recalculate coverage status
  $g->board(); # Re-render the board.
  $g->write('foo', 'png');

=head1 DESCRIPTION

This module exposes the "potential energy" of a chess ply by writing
an C<Imager> graphic of the board positions, pieces and their "attack
or protection status."

=head1 METHODS

=head2 new()

Return a new C<Chess::Coverage::Imager> object.

=head2 write($name, $type_extension)

  $filename = $g->write('my-board', 'png');

Return filename on success (as defined by simple existence) or undef on
failure.

=cut

sub write {
    my $self = shift;
    my ($name, $type) = @_;
    my $filename = "$name.$type";
    $self->board() unless $self->{board};
    $self->{board}->write(file => $filename, type => $type);
    return -e $filename ? $filename : undef;
}

=head2 board()

  $board = $g->board(%arguments);

Return an C<Imager> board layout with threats and protections
indicated by concentric colored circles.  Move status is indicated by
concentric colored squares.

These are the C<%arguments> with their default values, that you can
override in the call:

  border        => 2
  channels      => 4
  font_file     => undef # Set as /path/to/a/fontfile.ttf
  font_size     => 15
  grid          => 1 # Boolean
  letters       => 1 # Boolean
  max_coord     => 7 # Board side - 1
  margin        => 20
  square_height => 33
  square_width  => 33

  board_color         => #FFFFFF # white
  border_color        => #808080 # gray
  grid_color          => #C0C0C0 # silver
  letter_color        => #000000 # black
  white_move_color    => #00FF00 # lime
  black_move_color    => #FDD017 # gold
  white_threat_color  => #00FF00 # lime
  black_threat_color  => #FDD017 # gold
  white_protect_color => #00FF00 # lime
  black_protect_color => #FDD017 # gold

For instance, if you just want to see the white player protection as
lime green and threats from the black player as red, call C<board()>
with C<white_move_color>, C<black_move_color>, C<white_threat_color>,
and C<black_protect_color> all as C<#FFFFFF>, the
C<black_threat_color => '#FF0000'> and
C<white_protect_color => 00FF00>.

The FEN sequence in the C<Wikipedia> link under L<SEE ALSO>
graphically renders (with default colors) as:

=begin HTML

<p><img src="https://github.com/ology/Games/raw/master/Chess-Rep-Coverage/images/board-move-0.png" alt="Starting positions"></p>

<p><img src="https://github.com/ology/Games/raw/master/Chess-Rep-Coverage/images/board-move-1.png" alt="Move 1"></p>

<p><img src="https://github.com/ology/Games/raw/master/Chess-Rep-Coverage/images/board-move-2.png" alt="Move 2"></p>

<p><img src="https://github.com/ology/Games/raw/master/Chess-Rep-Coverage/images/board-move-3.png" alt="Move 3"></p>

<br>How about an animation of the famous "Immortal Game" between Garry Kasparov vs. Veselin Topalov, in 1999?</br>
<p><img src="https://github.com/ology/Games/raw/master/Chess-Rep-Coverage/images/immortal.gif" alt="The Immortal Game"></p>

=end HTML

=cut

sub board {
    my $self = shift;
    my %args = (
        border        => 2,
        channels      => 4,
        font_file     => '/System/Library/Fonts/HelveticaLight.ttf',
        font_size     => 15,
        grid          => 1,
        letters       => 1,
        max_coord     => 7,
        margin        => 20,
        square_height => 33,
        square_width  => 33,

        board_color         => '#FFFFFF', # white
        border_color        => '#808080', # gray
        grid_color          => '#C0C0C0', # silver
        letter_color        => '#000000', # black
        white_move_color    => '#00FF00', # lime
        black_move_color    => '#FDD017', # gold
        white_threat_color  => '#00FF00', # lime
#        white_threat_color  => '#F6358A', # violet red
        black_threat_color  => '#FDD017', # gold
#        black_threat_color  => '#6698FF', # sky blue
        white_protect_color => '#00FF00', # lime
#        white_protect_color => '#FAAFBE', # pink
        black_protect_color => '#FDD017', # gold
#        black_protect_color => '#ADA96E', # khaki
        white_arrow_color   => '#008000', # green
        black_arrow_color   => '#800080', # purple
        @_ # Argument averride
    );

    # Compute coverage if has not been done yet.
    $self->coverage() unless $self->_cover();

    # Compute dimensions.
    $args{board_size} = $args{max_coord} + 1;
    $args{image_width} = ($args{board_size} * $args{square_width})
        + $args{margin} + (2 * $args{border}) + $args{max_coord};
    $args{image_height} = ($args{board_size} * $args{square_height})
        + $args{margin} + (2 * $args{border}) + $args{max_coord};
    # Compute board boundaries.
    # Top-left
    $args{x0} = $args{margin};
    $args{y0} = $args{margin};
    # Bottom-right
    $args{x1} = $args{image_width}  - 1;
    $args{y1} = $args{image_height} - 1;

    # Instantiate a board object.
    my $board = Imager->new(
        xsize => $args{image_width},
        ysize => $args{image_height},
        channels => $args{channels},
    );
    # Draw the board background.
    $board->box(
        xmin => 0,
        ymin => 0,
        xmax => $args{image_width},
        ymax => $args{image_height},
        fill => Imager::Fill->new(solid => $args{board_color}),
    );
    # Draw the border.
    $board->box(
        xmin => $args{x0} + 1,
        ymin => $args{y0} + 1,
        xmax => $args{x1} - 1,
        ymax => $args{y1} - 1,
        color => $args{border_color},
    );

    # Render the board grid if reqested.
    if ($args{grid}) {
        for my $n (1 .. $args{max_coord}) {
            # Compute the grid dimensions.
            my($col, $row) = (
                $args{x0} + $args{border} + $n * $args{square_width}  + $n - 1,
                $args{y0} + $args{border} + $n * $args{square_height} + $n - 1,
            );
            # Vertical
            $board->line(
                x1    => $col,
                x2    => $col,
                y1    => $args{y0} + $args{border},
                y2    => $args{y1} - $args{border},
                color => $args{grid_color},
            );
            # Horizontal
            $board->line(
                x1    => $args{x0} + $args{border},
                x2    => $args{x1} - $args{border},
                y1    => $row,
                y2    => $row,
                color => $args{grid_color},
            );
        }
    }

    # Render column letters A-H and row numbers 1-8.
    if ($args{letters} && $args{font_file} && -e $args{font_file}) {
        $args{font} ||= Imager::Font->new(
            file  => $args{font_file},
            color => $args{letter_color},
            size  => $args{font_size},
        );

        my ($left, $top) = (0, 0);
        for my $n (0 .. $args{max_coord}) {
            # Compute the text positions.
            my $col = $args{x0} + $args{border} + $n
                + $n * $args{square_width}
                + $args{square_width} / 2
                + $args{square_width} / $args{max_coord}
                - $args{font_size} / 2;
            my $row = $args{y0} + $args{border} + $n
                + $n * $args{square_height}
                + $args{square_height} / 2
                + $args{square_height} / $args{max_coord};

            # Horizontal
            $board->string(
                font  => $args{font},
                text  => chr(ord('A') + $n),
                x     => $col - 1,
                y     => $top + $args{font_size},
                size  => $args{font_size},
                aa    => 1,
                color => $args{letter_color},
            );
            # Vertical
            $board->string(
                font  => $args{font},
                text  => $args{max_coord} + 1 - $n,
                x     => $left + $args{max_coord},
                y     => $row,
                size  => $args{font_size},
                aa    => 1,
                color => $args{letter_color},
            );
        }
    }

    # Consider each board position.
    for my $row (0 .. $args{max_coord}) {
        for my $col (0 .. $args{max_coord}) {
            my $position = chr(ord('A') + $row) . ($args{max_coord} + 1 - $col);

            my $xmin = $args{margin} + $args{border} + $row * ($args{square_width} + 1);
            my $ymin = $args{margin} + $args{border} + $col * ($args{square_height} + 1);
            my $xmax = $args{margin} + ($row + 1) * ($args{square_width} + 1);
            my $ymax = $args{margin} + ($col + 1) * ($args{square_height} + 1);

            # Show protection status.
           if (exists $self->_cover()->{$position}->{is_protected_by}) {
                my $i = 0;
                for my $pos (@{ $self->_cover()->{$position}{is_protected_by} }) {
                    my $piece = $self->get_piece_at($pos); # decimal of index
                    my $color = Chess::Rep::piece_color($piece); # 0=black, 0x80=white
                    $board->circle(
                        r      => $i * 2 + 1,
                        x      => $xmin + ($args{square_width} / 2),
                        y      => $ymin + ($args{square_height} / 2),
                        color  => $color ? $args{white_protect_color} : $args{black_protect_color},
                        filled => 0,
                    );
                    $i++;
                }
           }
            # Show threat status.
            if (exists $self->_cover()->{$position}->{is_threatened_by}) {
                my $i = 0;
                for my $pos (@{ $self->_cover()->{$position}{is_threatened_by} }) {
                    my $piece = $self->get_piece_at($pos); # decimal of index
                    my $color = Chess::Rep::piece_color($piece); # 0=black, 0x80=white
                    $board->circle(
                        r      => $i * 2 + 2,
                        x      => $xmin + ($args{square_width} / 2),
                        y      => $ymin + ($args{square_height} / 2),
                        color  => $color ? $args{white_threat_color} : $args{black_threat_color},
                        filled => 0,
                    );
                    $i++;
                }
            }
            # Show white movement status.
            if (exists $self->_cover()->{$position}{white_can_move_here}) {
                my $i = 0;
                for my $pos (@{ $self->_cover()->{$position}{white_can_move_here} }) {
                    $board->box(
                        xmin => $xmin + $i * 2,
                        ymin => $ymin + $i * 2,
                        xmax => $xmax - $i * 2,
                        ymax => $ymax - $i * 2,
                        color => $args{white_move_color},
                    );
                    $i++;
                }
            }
            # Show black movement status.
            if (exists $self->_cover()->{$position}{black_can_move_here}) {
                my $i = 0;
                for my $pos (@{ $self->_cover()->{$position}{black_can_move_here} }) {
                    $board->box(
                        xmin => $xmin + 1 + $i * 2,
                        ymin => $ymin + 1 + $i * 2,
                        xmax => $xmax - 1 - $i * 2,
                        ymax => $ymax - 1 - $i * 2,
                        color => $args{black_move_color},
                    );
                    $i++;
                }
            }
        }
    }

    $self->{board} = $board;
    return $board;
}

1;
__END__

=head1 SEE ALSO

* The code in the F<examples/> and F<t/> directories.

* L<Chess::Rep::Coverage>

* L<Imager>

* L<http://en.wikipedia.org/wiki/Forsyth-Edwards_Notation>

* L<http://www.chessgames.com/perl/chessgame?gid=1011478> (The "Immortal" game)

=cut
