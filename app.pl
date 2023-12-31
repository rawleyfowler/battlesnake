use 5.036;

use Dancer2;
use DDP;
use List::Util qw(reduce min);

use constant SNAKE_NAME => 'perlsnake';

set serializer => 'JSON';

sub _optimal_movement {
    my ( $viable_movements, $food, $hazards, $enemy_snakes, $length ) = @_;

    foreach my $m (@$viable_movements) {

        # Set a base cost factor (dt), lower is better.
        $m->{dt} //= 0;

        # Add the distance from fruit
        $m->{dt}
            += min( map { abs( $_->{x} - $m->{x} ) + abs( $_->{y} - $m->{y} ) }
                @$food );

        my @enemy_heads_and_lengths = map { +{ head => $_->{head}, length => scalar(@$_->{body}) } } @$enemy_snakes;

        for (@enemy_heads_and_lengths) {
            $m->{dt} = -1
                if ($_->{head}->{x} == $m->{x} &&
                    $_->{head}->{y} == $m->{y} &&
                    $length > $_->{length});
        }
    }

    return reduce { $a->{dt} <= $b->{dt} ? $a : $b } @$viable_movements;
}

sub _viable_movements {
    my ( $head, $hazards, $width, $height ) = @_;

    my @movements;
    my %h = %$hazards;

    my $dw = $width;
    my $dh = $height;

    my $x = $head->{x};
    my $y = $head->{y};

    my $make_direction = sub {
        my ( $dir, $nx, $ny ) = @_;
        return +{ direction => $dir, x => $nx, y => $ny };
    };

    my $safe = sub {
        my ( $nx, $ny ) = @_;
        return
               not( exists $h{ $nx . ',' . $ny } )
            && ( $nx >= 0 && $nx < $dw )
            && ( $ny >= 0 && $ny < $dh );
    };

    if ( ( my $dx = $x + 1 ) < $dw ) {
        say 'DX: ', $dx, ' Y: ', $y;
        push @movements, $make_direction->( 'right', $dx, $y )
            if $safe->( $dx, $y );
    }

    if ( ( my $dx = $x - 1 ) >= 0 ) {
        say 'DX: ', $dx, ' Y: ' . $y;
        push @movements, $make_direction->( 'left', $dx, $y )
            if $safe->( $dx, $y );
    }

    if ( ( my $dy = $y + 1 ) < $dh ) {
        say 'X: ', $x, ' DY: ', $dy;
        push @movements, $make_direction->( 'up', $x, $dy )
            if $safe->( $x, $dy );
    }

    if ( ( my $dy = $y - 1 ) >= 0 ) {
        say 'X: ', $x, ' DY: ', $dy;
        push @movements, $make_direction->( 'down', $x, $dy )
            if $safe->( $x, $dy );
    }

    say 'MOVEMENTS';
    p @movements;

    return \@movements;
}

sub _determine_move {
    my $map = shift;

    my $game  = $map->{game};
    my $turn  = $map->{turn};
    my $board = $map->{board};
    my $snake = $map->{you};

    my $head = $snake->{head};
    my $tail    = pop $snake->{body}->@*;
    my $height  = $board->{height};
    my $width   = $board->{width};
    my $hazards = $board->{hazards};
    my $food    = $board->{food};

    shift $snake->{body}->@*;
    push @$hazards, $snake->{body}->@*;

    unless ( $game->{snakes} ) {
        for ( $game->{snakes}->@* ) {
            next if $_->{id} eq $snake->{id};

            # Hazards includes bigger snake bodies
            if ( len( $_->{body} ) > ( len( $snake->{body} ) + 1 ) ) {
                push @$hazards, $_->{body}->@*;
            }
            else {
                my @body = grep {
                    $_->{x} != $_->{head}->{x} && $_->{y} != $_->{head}->{y}
                } $_->{body}->@*;
                push @$hazards, @body;
            }
        }
    }

    my %h;
    for (@$hazards) {
        $h{ $_->{x} . ',' . $_->{y} } = 1;
    }

    my $viable_movements = _viable_movements( $head, \%h, $width, $height );
    my $optimal_movement
        = _optimal_movement( $viable_movements, $food, $hazards, $game->{snakes}, scalar(@{$snake->{body}}) );

    return +{
        shout => 'PERL MAY BE OLD, BUT SHE SURE IS FAST!',
        move  => $optimal_movement->{direction}
    };
}

get '/' => sub {
    return +{
        apiversion => '1',
        author     => 'rawleyfowler',
        color      => '#0f0faa',
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
    $move = _determine_move($move);
    say 'PICKED MOVE:';
    p $move;
    return $move;
};

get '/end' => sub {
    say 'WE ENDING';
    return 'GG!';
};

open( my $fh, '>', '/tmp/battlesnake.pid' ) or die $!;
print $fh $$;
close($fh);

return to_app if $ENV{SNAKE_PRODUCTION};

dance;
