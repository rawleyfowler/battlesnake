use 5.036;

use Dancer2;
use DDP;
use List::Util qw(reduce min);

use constant SNAKE_NAME => 'perlsnake';

set serializer => 'JSON';

sub _optimal_movements {
    my ( $viable_movements, $food, $hazards ) = @_;

    foreach my $m (@$viable_movements) {
        my @dt =
          map { abs( $_->{x} - $m->{x} ) + abs( $_->{y} - $m->{y} ) } @$food;

        # TODO: Add based on hazards.

        $m->{dt} = min @dt;
    }

    return reduce { $a->{dt} <= $b->{dt} ? $a : $b } @$viable_movements;
}

sub _viable_movements {
    my ( $head, $hazards, $width, $height ) = @_;

    my @movements;

    my @hx = map { $_->{x} } @$hazards;
    my @hy = map { $_->{y} } @$hazards;

    my $dw = $width - 1;
    my $dh = $height - 1;

    my $x = $head->{x};
    my $y = $head->{y};

    my $make_direction = sub {
        my ( $dir, $nx, $ny ) = @_;
        return +{ direction => $dir, x => $nx, y => $ny };
    };

    if ( ( my $dx = $x + 1 ) < $dw ) {
        push @movements, $make_direction->( 'right', $dx, $y )
          unless grep { $_ == $dx } @hx;
    }

    if ( ( my $dx = $x - 1 ) >= 0 ) {
        push @movements, $make_direction->( 'left', $dx, $y )
          unless grep { $_ == $dx } @hx;
    }

    if ( ( my $dy = $y + 1 ) < $dh ) {
        push @movements, $make_direction->( 'up', $x, $dy )
          unless grep { $_ == $dy } @hy;
    }

    if ( ( my $dy = $y - 1 ) > 0 ) {
        push @movements, $make_direction->( 'down', $x, $dy )
          unless grep { $_ == $dy } @hy;
    }

    return \@movements;
}

sub _determine_move {
    my $map = shift;

    my $game  = $map->{game};
    my $turn  = $map->{turn};
    my $board = $map->{board};
    my $snake = $map->{you};

    my $head    = $snake->{head};
    my $tail    = pop $snake->{body}->@*;
    my $height  = $board->{height};
    my $width   = $board->{width};
    my $hazards = $board->{hazards};
    my $food    = $board->{food};

    $snake->{body} = [ grep { $_->{x} != $head->{x} && $_->{y} != $head->{y} }
          $snake->{body}->@* ];

    push @$hazards, $snake->{body}->@*;

    goto SOLO unless $game->{snakes};

    for ( $game->{snakes}->@* ) {
        next if $_->{id} eq $snake->{id};

        # Hazards includes bigger snake bodies
        if ( $_->{health} > $snake->{health} ) {
            push @$hazards, $_->{body}->@*;
        }
        else {
            my @body =
              grep { $_->{x} != $_->{head}->{x} && $_->{y} != $_->{head}->{y} }
              $_->{body}->@*;
            push @$hazards, @body;
        }
    }

  SOLO:

    my $viable_movements =
      _viable_movements( $head, $hazards, $width, $height );
    my $optimal_movement =
      _optimal_movement( $viable_movements, $food, $hazards );

    p $optimal_movement;

    return +{
        shout => 'PERL MAY BE OLD, BUT SHE SURE IS FAST!',
        move  => $optimal_movement->{direction}
    };
}

get '/' => sub {
    return +{
        apiversion => '1',
        author     => 'rawleyfowler',
        color      => '#ffffff',
        head       => 'default',
        tail       => 'default'
    };
};

post '/start' => sub {
    say 'WE STARTING';
    return +{};
};

post '/move' => sub {
    my $move = from_json( request->body );
    p $move;
    return _determine_move($move);
};

return to_app if $ENV{SNAKE_PRODUCTION};

dance;
