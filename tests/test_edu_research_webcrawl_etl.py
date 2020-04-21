#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Tests for `edu_research_webcrawl_etl` package."""

import pytest


from edu_research_webcrawl_etl import edu_research_webcrawl_etl


@pytest.fixture
def response():
    """Sample pytest fixture.

    See more at: http://doc.pytest.org/en/latest/fixture.html
    """
    # import requests
    # return requests.get('https://github.com/audreyr/cookiecutter-pypackage')


def test_content(response):
    """Sample pytest test function with the pytest fixture as an argument."""
    # from bs4 import BeautifulSoup
    # assert 'GitHub' in BeautifulSoup(response.content).title.string
