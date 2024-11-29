/* SPDX-License-Identifier: LGPL-2.1-or-later */

/* getopt_long and getopt_long_only entry points for GNU getopt.
   Copyright (C) 1987-2023 Free Software Foundation, Inc.
   This file is part of the GNU C Library and is also part of gnulib.
   Patches to this file should be submitted to both projects.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <https://www.gnu.org/licenses/>.

   Update: Saykachi | 29.11.2024
   */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "getopt.h"
#include "getopt_int.h"

int getopt_long(int argc, char *__getopt_argv_const *argv, const char *options,
                const struct option *long_options, int *opt_index) {
    if (!argv || !options || !long_options) {
        fprintf(stderr, "Error: Null pointer passed to getopt_long.\n");
        return -1; // Return error code
    }
    return _getopt_internal(argc, (char **)argv, options, long_options, opt_index, 0, 0);
}

int getopt_long_only(int argc, char *__getopt_argv_const *argv,
                     const char *options,
                     const struct option *long_options, int *opt_index) {
    if (!argv || !options || !long_options) {
        fprintf(stderr, "Error: Null pointer passed to getopt_long_only.\n");
        return -1; // Return error code
    }
    return _getopt_internal(argc, (char **)argv, options, long_options, opt_index, 1, 0);
}

#ifdef TEST

int main(int argc, char **argv) {
    int c;
    int digit_optind = 0;

    static const struct option long_options[] = {
        {"add", required_argument, 0, 0},
        {"append", no_argument, 0, 0},
        {"delete", required_argument, 0, 0},
        {"verbose", no_argument, 0, 0},
        {"create", no_argument, 0, 0},
        {"file", required_argument, 0, 0},
        {0, 0, 0, 0}
    };

    while (1) {
        int option_index = 0;
        c = getopt_long(argc, argv, "abc:d:0123456789", long_options, &option_index);

        if (c == -1) break; // End of options

        switch (c) {
            case 0:
                printf("option %s", long_options[option_index].name);
                if (optarg)
                    printf(" with arg %s", optarg);
                printf("\n");
                break;

            case 'a':
            case 'b':
                printf("option %c\n", c);
                break;

            case 'c':
            case 'd':
                printf("option %c with value '%s'\n", c, optarg);
                break;

            case '0' ... '9':
                if (digit_optind != 0 && digit_optind != optind)
                    printf("digits occur in two different argv-elements.\n");
                digit_optind = optind;
                printf("option %c\n", c);
                break;

            case '?':
                printf("Unknown option.\n");
                break;

            default:
                printf("?? getopt returned character code 0%o ??\n", c);
        }
    }

    if (optind < argc) {
        printf("non-option ARGV-elements: ");
        while (optind < argc)
            printf("%s ", argv[optind++]);
        printf("\n");
    }

    return 0;
}

#endif /* TEST */
