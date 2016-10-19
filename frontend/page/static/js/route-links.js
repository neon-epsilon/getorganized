var navigateTo = function (url) {
  window.history.pushState({}, document.title, url);
  window.dispatchEvent(new Event('popstate'));
}

var routeLinks = document.querySelectorAll("a.route-link");

var turnLinkIntoRouteLink = function(routeLink) {
  routeLink.addEventListener('click', function(clickEvent) {
    clickEvent.preventDefault();
    var url = clickEvent.target.getAttribute('href');
    navigateTo(url);
  });
};

[].forEach.call(
  routeLinks,
  turnLinkIntoRouteLink
);
