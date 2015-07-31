[% USE date %]

<?xml version="1.0" encoding="iso-8859-15"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>AWStats MultiSite Summary for "[% username %]"</title>
    [% IF refresh > 0 %]
    <meta http-equiv="refresh" content="[% refresh %]">
    [% END %]
    <meta http-equiv="Content-Style-Type" content="text/css" />

    <style type="text/css">
      <!--
      body {
         font            : 12px/1.2 Verdana, Arial, Helvetica, Sans-Serif;
         text-align      : center;
      }

      td {
         font            : 12px/1.2 Verdana, Arial, Helvetica, Sans-Serif;
      }

      td.header {
         font            : 12px/1.2 Verdana, Arial, Helvetica, Sans-Serif;
         text-align      : center;
         font-weight     : bold;
      }

      p.disclaimer {
         font            : 10px/1.2 Verdana, Arial, Helvetica, Sans-Serif;
         text-align      : center;
      }

      h1 {
         font            : 14px/1.4 Verdana, Arial, Helvetica, Sans-Serif;
         font-weight     : bold;
         text-align      : center;
      }

      #content {
         width           : 640px;
         margin-right    : auto;
         margin-left     : auto;
         margin-top      : 10px;
         padding         : 0px;
         text-align      : left;
      }

      a.header:link, a.header:visited, a.header:active {
         color           : #000000;
         text-decoration : none;
      }

      a.header:hover {
         text-decoration : underline;
      }
      -->
    </style>
  </head>

  <body>

    <div id="content">
      <h1>AWStats MultiSite Summary<br>for user "[% username %]"</h1>

      [% IF errors.size %]
        <p>Error(s):</p>
        <ul>
          [% FOREACH error = errors %]
            <li>[% error.replace(' at .*', '') %]</li>
          [% END %]
        </ul>
      [% END %]

      <table border="0" cellspacing="4" cellpadding="4">
        <tr>
          <td class="header" width="100" bgcolor="#ECECEC"><a href="?s=name&t=alnum" class="header">Statistics for</a></td>
          <td class="header" width="75" bgcolor="#FFB055"><a href="?s=visitors" class="header">Unique visitors</a></td>
          <td class="header" width="75" bgcolor="#F8E880"><a href="?s=visits" class="header">Number of visits</a></td>
          <td class="header" width="75" bgcolor="#4477DD"><a href="?s=pages" class="header">Pages</a></td>
          <td class="header" width="75" bgcolor="#66F0FF"><a href="?s=hits" class="header">Hits</a></td>
          <td class="header" width="75" bgcolor="#2EA495"><a href="?s=bandwidth_bytes" class="header">Bandwidth</a></td>
          <td class="header" width="75" bgcolor="#ECECEC"><a href="?s=lasttime&t=alnum" class="header">Last<br>Access</a></td>
          <td class="header" width="75" bgcolor="#ECECEC"><a href="?s=lastupdate&t=alnum" class="header">Last<br>Update</a></td>
        </tr>
        [%- FOREACH site = sites %]
          <tr>
            <td nowrap><a href="[% awstats %]?config=[% site.configname %]" onMouseover="window.status='Statistics for [% site.name %]'; return true;" onMouseout="window.status=''; return true;">[% site.name %]</td>
            <td align="right">[% site.visitors %]</td>
            <td align="right">[% site.visits %]</td>
            <td align="right">[% site.pages %]</td>
            <td align="right">[% site.hits %]</td>
            <td align="right">[% site.bandwidth %] [% site.bandwidth_suffix %]</td>
            <td align="right" nowrap>[% site.lasttime %]</td>
            <td align="right" nowrap>[% site.lastupdate %]</td>
          </tr>
        [%- END %]
      </table>

      <p>To get a detailed view please click on the corresponding link.</p>
      [% INCLUDE footer.tpl %]
    </div>

  </body>
</html>
