use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use Tests;

my %dsn;

test {
  my $c = shift;
  my $client = AnyEvent::MySQL::Client->new;
  $client->statement_close (124)->then (sub {
    test {
      ok 0;
    } $c;
  }, sub {
    my $x = $_[0];
    test {
      ok $x;
      isa_ok $x, 'AnyEvent::MySQL::Client::Result';
      ok $x->is_exception;
    } $c;
  })->then (sub {
    test {
      done $c;
      undef $c;
      undef $client;
    } $c;
  });
} n => 3, name => 'not connected';

test {
  my $c = shift;
  my $client = AnyEvent::MySQL::Client->new;
  $client->connect
      (hostname => 'unix/', port => $dsn{mysql_socket},
       username => $dsn{user}, password => $dsn{password},
       database => $dsn{dbname})->then (sub {
    return $client->statement_prepare ('create table foo0 (id int)');
  })->then (sub {
    return $client->statement_close ($_[0]->packet->{statement_id})->die;
  })->catch (sub {
    test {
      ok 1;
    } $c;
    return $client->disconnect;
  })->then (sub {
    test {
      ok 1;
      done $c;
      undef $c;
      undef $client;
    } $c;
  });
} n => 2, name => 'close die';

test {
  my $c = shift;
  my $client = AnyEvent::MySQL::Client->new;
  $client->connect
      (hostname => 'unix/', port => $dsn{mysql_socket},
       username => $dsn{user}, password => $dsn{password},
       database => $dsn{dbname})->then (sub {
    return $client->statement_close;
  })->catch (sub {
    my $x = $_[0];
    test {
      ok $x;
    } $c;
  })->then (sub {
    return $client->disconnect;
  })->then (sub {
    test {
      done $c;
      undef $c;
      undef $client;
    } $c;
  });
} n => 1, name => 'no statement id';

test {
  my $c = shift;
  my $client = AnyEvent::MySQL::Client->new;
  my $statement_id;
  $client->connect
      (hostname => 'unix/', port => $dsn{mysql_socket},
       username => $dsn{user}, password => $dsn{password},
       database => $dsn{dbname})->then (sub {
    return $client->query ('create table foo1 (id int)');
  })->then (sub {
    return $client->statement_prepare ('insert into foo1 (id) values (12)');
  })->then (sub {
    my $result = $_[0];
    $statement_id = $result->packet->{statement_id};
    return $client->statement_close ($statement_id);
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result;
      isa_ok $result, 'AnyEvent::MySQL::Client::Result';
      ok $result->is_success;
      is $result->packet, undef;
    } $c;
  })->then (sub {
    return $client->statement_execute ($statement_id);
  })->then (sub {
    my $x = $_[0];
    test {
      ok $x->is_failure;
      is $x->packet->{error_code}, 1243;
    } $c;
    my $data;
    return $client->query ('select * from foo1', sub {
      $data = $_[0]->packet->{data};
    })->then (sub { return $data });
  })->then (sub {
    my $result = $_[0];
    test {
      is_deeply $result, undef;
    } $c;
  })->catch (sub {
    warn $_[0];
    test {
      ok 0;
    } $c;
  })->then (sub {
    return $client->disconnect;
  })->then (sub {
    test {
      done $c;
      undef $c;
      undef $client;
    } $c;
  });
} n => 7, name => 'close ok';

test {
  my $c = shift;
  my $client = AnyEvent::MySQL::Client->new;
  my $statement_id;
  $client->connect
      (hostname => 'unix/', port => $dsn{mysql_socket},
       username => $dsn{user}, password => $dsn{password},
       database => $dsn{dbname})->then (sub {
    return $client->query ('create table foo2 (id int)');
  })->then (sub {
    return $client->statement_prepare ('insert into foo2 (id) values (12)');
  })->then (sub {
    my $result = $_[0];
    $statement_id = $result->packet->{statement_id};
    return $client->statement_close ($statement_id + 30);
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result;
      isa_ok $result, 'AnyEvent::MySQL::Client::Result';
      ok $result->is_success;
      is $result->packet, undef;
    } $c;
  })->then (sub {
    return $client->statement_execute ($statement_id);
  })->then (sub {
    my $x = $_[0];
    test {
      ok 1;
    } $c;
    my $data;
    return $client->query ('select * from foo2', sub {
      $data = $_[0]->packet->{data};
    })->then (sub { return $data });
  })->then (sub {
    my $result = $_[0];
    test {
      is_deeply $result, [12];
    } $c;
  })->catch (sub {
    warn $_[0];
    test {
      ok 0;
    } $c;
  })->then (sub {
    return $client->disconnect;
  })->then (sub {
    test {
      done $c;
      undef $c;
      undef $client;
    } $c;
  });
} n => 6, name => 'close not exist';

test {
  my $c = shift;
  my $client = AnyEvent::MySQL::Client->new;
  my $statement_id;
  $client->connect
      (hostname => 'unix/', port => $dsn{mysql_socket},
       username => $dsn{user}, password => $dsn{password},
       database => $dsn{dbname})->then (sub {
    return $client->query ('create table foo1 (id int)');
  })->then (sub {
    return $client->statement_prepare ('insert into foo1 (id) values (12)');
  })->then (sub {
    my $result = $_[0];
    $statement_id = $result->packet->{statement_id};
    $client->statement_close ($statement_id);
    return $client->disconnect;
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result;
      isa_ok $result, 'AnyEvent::MySQL::Client::Result';
      ok $result->is_success;
    } $c;
  })->catch (sub {
    warn $_[0];
    test {
      ok 0;
    } $c;
  })->then (sub {
    test {
      done $c;
      undef $c;
      undef $client;
    } $c;
  });
} n => 3, name => 'close then soon disconnect';

test {
  my $c = shift;
  my $client = AnyEvent::MySQL::Client->new;
  my $statement_id;
  $client->connect
      (hostname => 'unix/', port => $dsn{mysql_socket},
       username => $dsn{user}, password => $dsn{password},
       database => $dsn{dbname})->then (sub {
    return $client->query ('create table foo1 (id int)');
  })->then (sub {
    return $client->statement_prepare ('insert into foo1 (id) values (12)');
  })->then (sub {
    my $result = $_[0];
    $statement_id = $result->packet->{statement_id};
    $client->disconnect;
    return $client->statement_close ($statement_id);
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result;
      isa_ok $result, 'AnyEvent::MySQL::Client::Result';
      ok $result->is_success;
    } $c;
  })->catch (sub {
    warn $_[0];
    test {
      ok 0;
    } $c;
  })->then (sub {
    test {
      done $c;
      undef $c;
      undef $client;
    } $c;
  });
} n => 3, name => 'disconnect then soon close';

RUN sub {
  my $dsn = test_dsn 'hoge';
  $dsn =~ s/^DBI:mysql://i;
  %dsn = map { split /=/, $_, 2 } split /;/, $dsn;
};

=head1 LICENSE

Copyright 2014-2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
