<%@include file="jsp/header.jsp"%>
<%@page pageEncoding="UTF-8"%>
<%@include file="jsp/navbar.jsp"%>
<%@include file="jsp/info-section.jsp"%>
<%@include file="jsp/search-section.jsp"%>
<%@ page import = "  javax.servlet.*, javax.servlet.http.*, java.io.*, java.net.URLEncoder, java.net.URLDecoder, java.nio.file.Paths, org.apache.lucene.analysis.Analyzer, org.apache.lucene.analysis.TokenStream, org.apache.lucene.analysis.standard.StandardAnalyzer, org.apache.lucene.analysis.th.ThaiAnalyzer, org.apache.lucene.document.Document, org.apache.lucene.index.DirectoryReader, org.apache.lucene.index.IndexReader, org.apache.lucene.queryparser.classic.QueryParser, org.apache.lucene.queryparser.classic.ParseException, org.apache.lucene.search.IndexSearcher, org.apache.lucene.search.Query, org.apache.lucene.search.ScoreDoc, org.apache.lucene.search.TopDocs, org.apache.lucene.search.highlight.Highlighter, org.apache.lucene.search.highlight.InvalidTokenOffsetsException, org.apache.lucene.search.highlight.QueryScorer, org.apache.lucene.search.highlight.SimpleFragmenter, org.apache.lucene.store.FSDirectory" %>

<%!
public String escapeHTML(String s) {
  s = s.replaceAll("&", "&amp;");
  s = s.replaceAll("<", "&lt;");
  s = s.replaceAll(">", "&gt;");
  s = s.replaceAll("\"", "&quot;");
  s = s.replaceAll("'", "&apos;");
  return s;
}
%>

<%
        boolean error = false;                  //used to control flow for error messages
        String indexName = indexLocation;       //local copy of the configuration variable
        IndexSearcher searcher = null;          //the searcher used to open/search the index
        Query query = null;                     //the Query created by the QueryParser
        TopDocs hits = null;                       //the search results
        int startindex = 0;                     //the first index displayed on this page
        int maxpage    = 50;                    //the maximum items displayed on this page
        String queryString = null;              //the query entered in the previous page
        String startVal    = null;              //string version of startindex
        String maxresults  = null;              //string version of maxpage
        int thispage = 0;                       //used for the for/next either maxpage or
                                                //hits.totalHits - startindex - whichever is
                                                //less
        String search_method = null;


        try {
          IndexReader reader = DirectoryReader.open(FSDirectory.open(Paths.get(indexName)));
          searcher = new IndexSearcher(reader);         //create an indexSearcher for our page
                                                        //NOTE: this operation is slow for large
                                                        //indices (much slower than the search itself)
                                                        //so you might want to keep an IndexSearcher 
                                                        //open
                                                        
        } catch (Exception e) {                         //any error that happens is probably due
                                                        //to a permission problem or non-existant
                                                        //or otherwise corrupt index
%>
                <p>ERROR opening the Index - contact sysadmin!</p>
                <p>Error message: <%=escapeHTML(e.getMessage())%></p>   
<%                error = true;                                  //don't do anything up to the footer
        }
%>
<%
       if (error == false ) {                                           //did we open the index?
                //queryString = URLDecoder.decode(request.getParameter("query"),"UTF-8");           //get the search criteria
                queryString = request.getParameter("query");           //get the search criteria
                startVal    = request.getParameter("startat");         //get the start index
                maxresults  = request.getParameter("maxresults");      //get max results per page
                search_method = request.getParameter("search_method");

                try {
                        maxpage    = Integer.parseInt(maxresults);    //parse the max results first
                        startindex = Integer.parseInt(startVal);      //then the start index  
                } catch (Exception e) { } //we don't care if something happens we'll just start at 0
                                          //or end at 50

                

                if (queryString == null)
                        throw new ServletException("no query "+       //if you don't have a query then
                                                   "specified");      //you probably played on the 
                                                                      //query string so you get the 
                                                                      //treatment

                //Analyzer analyzer = new StandardAnalyzer(Version.LUCENE_CURRENT);           //construct our usual analyzer
                Analyzer analyzer = new ThaiAnalyzer();
                try {
                        QueryParser qp = new QueryParser("contents", analyzer);
                        query = qp.parse(queryString.trim()); //parse the 
                } catch (ParseException e) {                          //query and construct the Query
                                                                      //object
                                                                      //if it's just "operator error"
                                                                      //send them a nice error HTML
                                                                      
%>
                        <!-- <p>Error while parsing query: <%=escapeHTML(e.getMessage())%></p> -->
                        <div class="notification is-danger">
                          <div class="container">
                            <h6 class="subtitle">Prease Type a keyword before search.</h6>
                          </div>
                        </div>
<%
                        error = true;                                 //don't bother with the rest of
                                                                      //the page
                }
        }
%>
<%
        if (error == false && searcher != null) {                     // if we've had no errors
                                                                      // searcher != null was to handle
                                                                      // a weird compilation bug 
                thispage = maxpage;                                   // default last element to maxpage
                hits = searcher.search(query, maxpage + startindex);  // run the query 
                if (hits.totalHits == 0) {                             // if we got no results tell the user
%>
                <div class="notification is-danger">
                  <div class="container">
                    <h6 class="subtitle">I'm sorry I couldn't find what you were looking for. Prease type a new keyword.</h6>
                  </div>
                </div>
<%
                error = true;                                        // don't bother with the rest of the
                                                                     // page
                }
        }

        if (error == false && searcher != null) {                   
%>
                <div class="notification is-info">
                  <div class="container">
                    <h6 class="subtitle">Searching for
                      <span class="title is-4">"<%=queryString%>" </span>
                      by 
                      <span class="title is-4"> "<%=search_method%>"</span>
                    </h6>
                  </div>
                </div>
<%
                if ((startindex + maxpage) > hits.totalHits) {
                        thispage = hits.totalHits - startindex;      // set the max index to maxpage or last
                }                                                   // actual search result whichever is less

                for (int i = startindex; i < (thispage + startindex); i++) {  // for each element
%>

<%
                        Document doc = searcher.doc(hits.scoreDocs[i].doc);                    //get the next document 
                        String doctitle = doc.get("title");            //get its title
                        String path = doc.get("path");                  //get its path field
                        if (path != null && path.startsWith("../webapps/")) { // strip off ../webapps prefix if present
                                path = path.substring(10);
                        }
                        if ((doctitle == null) || doctitle.equals("")) //use the path if it has no title
                                doctitle = path;
                                                                       //then output!
%>
                <div class="box">
                  <article class="media">
                    
                    <div class="media-left">
                      <h1 class="title"><%=i+1%></h1>
                    </div>

                    <div class="media-content">
                      <div class="content">
                        <h4 class="title is-4"  style="color: blue;">
                          <%=doctitle%>
                        <h4>
                        <h4 class="subtitle">
                          <%=doc.get("snippet")%>
                        </h4>
                        <a href=<%=doc.get("URL")%> >
                          <h4 class="subtitle" style="color: green;">
                            <%=doc.get("URL")%>
                          </h4>
                        </a>
                      </div>
                    </div>
                  </article>
                </div>
                
<%
                }
%>
<%                if ( (startindex + maxpage) < hits.totalHits) {   //if there are more results...display 
                                                                   //the more link

                        String moreurl="results.jsp?query=" + 
                                       URLEncoder.encode(queryString) +  //construct the "more" link
                                       "&amp;maxresults=" + maxpage + 
                                       "&amp;startat=" + (startindex + maxpage);
%>
                    <div class="box">
                      <article class="media">
                        <div class="media-content">
                          <div class="content">
                            <center>
                              <a href="<%=moreurl%>" class="button is-info is-medium">
                                More Results
                              </a>
                            </center>
                          </div>
                        </div>
                      </article>
                    </div>
<%
                }
%>

<%       }                                    //then include our footer.
         //if (searcher != null)
         //       searcher.close();
%>

<%@include file="jsp/members-modal.jsp"%>
<%@include file="jsp/footer.jsp"%>        